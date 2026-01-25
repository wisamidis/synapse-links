import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/synapse_entity.dart';
import '../core/synapse_operation.dart';
import '../core/synapse_repository.dart';
import '../core/synapse_config.dart';
import '../core/synapse_exception.dart'; 
import '../sync/delta_sync_engine.dart';
import '../network/synapse_network.dart';
import '../storage/synapse_storage.dart';
import '../sync/queue_item.dart';
import '../core/synapse_search_engine.dart';
import '../sync/queue_storage.dart';
import '../sync/conflict_resolver.dart';
import '../sync/smart_merge_strategy.dart';

typedef SynapseValidator<T> = void Function(T item);

class SynapseRepositoryImpl<T extends SynapseEntity> implements SynapseRepository<T> {
  final SynapseStorage<T> _storage;
  final SynapseNetwork<T> _network;
  final QueueStorage _queueStorage;
  final ConflictResolver<T> _resolver;
  final SynapseConfig _config;
  final SynapseValidator<T>? _validator;

  final Uuid _uuid = const Uuid();
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  final BehaviorSubject<List<T>> _dataStream = BehaviorSubject<List<T>>.seeded([]);
  final BehaviorSubject<SynapseSyncStatus> _statusStream = BehaviorSubject<SynapseSyncStatus>.seeded(SynapseSyncStatus.idle);

  final Map<String, T> _rollbackBackup = {};
  bool _isSyncing = false;
  bool _isPausedForAuth = false;
  bool _initialized = false;

  SynapseRepositoryImpl({
    required SynapseStorage<T> storage,
    required SynapseNetwork<T> network,
    required QueueStorage queueStorage,
    ConflictResolver<T>? resolver,
    SynapseConfig? config,
    SynapseValidator<T>? validator,
  })  : _storage = storage,
        _network = network,
        _queueStorage = queueStorage,
        _resolver = resolver ?? SmartMergeStrategy<T>(),
        _config = config ?? const SynapseConfig(),
        _validator = validator {
    // Lazy Initialization: Fire and forget, don't block the constructor.
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    try {
      // 1. Load Local Data Immediately
      final localData = await _storage.readAll();
      _dataStream.add(localData);
      _initialized = true;

      // 2. Clear expired cache if needed (Feature: TTL)
      if (_config.clearExpiredCache) {
         // Logic handled inside storage drivers usually, or could be triggered here
      }

      // 3. Attempt to Sync Pending Queue
      _syncPendingItems();
    } catch (e) {
      debugPrint("Synapse Init Error: $e");
    }
  }

  void dispose() {
    _dataStream.close();
    _statusStream.close();
  }
  
  void resumeSync() {
    debugPrint("🔐 Auth refreshed. Resuming sync...");
    _isPausedForAuth = false;
    _statusStream.add(SynapseSyncStatus.idle);
    _syncPendingItems();
  }

  @override
  Stream<List<T>> watchAll() => _dataStream.stream;

  @override
  Stream<SynapseSyncStatus> watchSyncStatus() => _statusStream.stream;

  @override
  Future<void> add(T item) async {
    // Feature 14: Validation Hook
    if (_validator != null) {
      try {
        _validator!(item);
      } catch (e) {
        throw SynapseException('Validation failed: $e');
      }
    }

    _updateLocalState(item);
    await _storage.write(item);
    await _addToQueue(item.id, SynapseOperationType.create, item.toJson());
    _syncPendingItems();
  }

  @override
  Future<void> update(T item) async {
    // Feature 14: Validation Hook
    if (_validator != null) {
      try {
        _validator!(item);
      } catch (e) {
        throw SynapseException('Validation failed: $e');
      }
    }

    final currentList = _dataStream.value;
    final oldItem = currentList.firstWhere((e) => e.id == item.id, orElse: () => item);
    _rollbackBackup[item.id] = oldItem;

    _updateLocalState(item);
    await _storage.write(item);

    final delta = DeltaSyncEngine.calculateDelta(oldItem.toJson(), item.toJson());
    if (delta.isNotEmpty) {
      await _addToQueue(item.id, SynapseOperationType.update, delta);
      _syncPendingItems();
    }
  }

  @override
  Future<void> delete(String id) async {
    final currentList = _dataStream.value;
    try {
      final itemToDelete = currentList.firstWhere((e) => e.id == id);
      _rollbackBackup[id] = itemToDelete;
    } catch (_) {}

    final newList = [...currentList]..removeWhere((e) => e.id == id);
    _dataStream.add(newList);
    
    await _storage.delete(id);
    await _addToQueue(id, SynapseOperationType.delete, {'id': id});
    _syncPendingItems();
  }

  @override
  Future<String> upload(String filePath, {String? targetEntityId}) async {
    final taskId = _uuid.v4();
    await _addToQueue(
      taskId, 
      SynapseOperationType.upload, 
      {
        'path': filePath,
        'targetEntityId': targetEntityId, 
      }
    );
    _syncPendingItems();
    return taskId;
  }

  @override
  Future<List<T>> search(String query) async {
    return SynapseSearchEngine.search(_dataStream.value, query);
  }

  @override
  Future<void> refresh() async {
    if (_isPausedForAuth) return;

    _statusStream.add(SynapseSyncStatus.syncing);
    try {
      final remoteItems = await _network.fetchAll();
      final localItems = _dataStream.value;
      final mergedItems = _resolver.resolve(localItems: localItems, remoteItems: remoteItems);

      await _storage.clear();
      for (var item in mergedItems) {
        await _storage.write(item);
      }

      _dataStream.add(mergedItems);
      await _syncPendingItems();

      if (_statusStream.value != SynapseSyncStatus.error && _statusStream.value != SynapseSyncStatus.offline) {
        _statusStream.add(SynapseSyncStatus.idle);
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) {
         _isPausedForAuth = true;
         debugPrint("⛔ Auth Error (401). Pausing Sync.");
         _statusStream.add(SynapseSyncStatus.error);
      } else {
         debugPrint('Refresh failed: $e');
         _statusStream.add(SynapseSyncStatus.error);
      }
    }
  }

  @override
  Future<List<QueueItem>> getQueueSnapshot() => _queueStorage.getAll();

  @override
  Future<void> clear() async {
    _dataStream.add([]);
    await _storage.clear();
    await _queueStorage.clear();
  }

  void _updateLocalState(T item) {
    final currentList = [..._dataStream.value];
    final index = currentList.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      currentList[index] = item;
    } else {
      currentList.add(item);
    }
    _dataStream.add(currentList);
  }

  Future<void> _addToQueue(String entityId, SynapseOperationType type, Map<String, dynamic> payload) async {
    final item = QueueItem(
      id: _uuid.v4(),
      entityId: entityId,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _queueStorage.add(item);
  }

  Future<void> _performRollback(String entityId) async {
    if (_rollbackBackup.containsKey(entityId)) {
      final originalItem = _rollbackBackup[entityId]!;
      _updateLocalState(originalItem);
      await _storage.write(originalItem);
      _rollbackBackup.remove(entityId);
      debugPrint('🔄 Rolled back item $entityId');
    } else {
      final currentList = [..._dataStream.value]..removeWhere((e) => e.id == entityId);
      _dataStream.add(currentList);
      await _storage.delete(entityId);
      debugPrint('🔄 Rolled back creation of $entityId');
    }
  }

  Future<bool> _checkSyncConstraints() async {
    if (_config.syncPolicy == SynapseSyncPolicy.immediate) return true;

    if (_config.syncPolicy == SynapseSyncPolicy.wifiOnly || _config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final result = await _connectivity.checkConnectivity();
      if (!result.contains(ConnectivityResult.wifi)) return false;
    }

    if (_config.syncPolicy == SynapseSyncPolicy.chargingOnly || _config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final batteryState = await _battery.batteryState;
      if (batteryState != BatteryState.charging && batteryState != BatteryState.full) return false;
    }

    return true;
  }

  Future<void> _syncPendingItems() async {
    if (_isSyncing || _isPausedForAuth) return;
    _isSyncing = true;

    try {
      var queue = await _queueStorage.getAll();
      if (queue.isEmpty) {
        if (_statusStream.value != SynapseSyncStatus.error) {
          _statusStream.add(SynapseSyncStatus.idle);
        }
        return;
      }

      final canSync = await _checkSyncConstraints();
      if (!canSync) {
        _statusStream.add(SynapseSyncStatus.offline);
        return;
      }

      _statusStream.add(SynapseSyncStatus.syncing);

      // Batch Optimization
      if (queue.length >= 5) { 
         final batchCreateItems = queue.where((i) => i.type == SynapseOperationType.create).toList();
         if (batchCreateItems.length >= 2) {
           try {
              final payloads = batchCreateItems.map((e) => e.payload).toList();
              await _network.batchCreate(payloads);
              for(var item in batchCreateItems) {
                 await _queueStorage.remove(item.id);
                 _rollbackBackup.remove(item.entityId);
              }
              queue = await _queueStorage.getAll();
           } catch (e) {
              debugPrint("Batch failed, falling back to single sync: $e");
           }
         }
      }

      for (final item in queue) {
        if (_isPausedForAuth) break;

        try {
          switch (item.type) {
            case SynapseOperationType.create:
              await _network.create(item.payload);
              break;
            case SynapseOperationType.update:
              await _network.update(item.entityId, item.payload);
              break;
            case SynapseOperationType.delete:
              await _network.delete(item.entityId);
              break;
            case SynapseOperationType.upload:
              final path = item.payload['path'];
              if (path != null) await _network.uploadFile(path);
              break;
          }
          await _queueStorage.remove(item.id);
          _rollbackBackup.remove(item.entityId);
        
        } catch (e) {
          debugPrint('Sync Error for item ${item.id}: $e');
          
          if (e is NetworkException && e.statusCode == 401) {
             _isPausedForAuth = true;
             debugPrint("⛔ Auth Error (401). Pausing queue.");
             _statusStream.add(SynapseSyncStatus.error);
             break;
          }

          await _performRollback(item.entityId);
          await _queueStorage.remove(item.id);
          _statusStream.add(SynapseSyncStatus.error);
        }
      }
      
      final remaining = await _queueStorage.getAll();
      if (remaining.isEmpty && !_isPausedForAuth) {
        _statusStream.add(SynapseSyncStatus.idle);
      }
    } finally {
      _isSyncing = false;
    }
  }
}