import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synapse_link/src/core/synapse_operation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

import '../core/synapse_entity.dart';
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

class SynapseRepositoryImpl<T extends SynapseEntity> implements SynapseRepository<T> {
  final SynapseStorage<T> _storage;
  final SynapseNetwork<T> _network;
  final QueueStorage _queueStorage;
  final ConflictResolver<T> _resolver;
  final SynapseConfig _config;

  final Uuid _uuid = const Uuid();
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  final BehaviorSubject<List<T>> _dataStream = BehaviorSubject<List<T>>.seeded([]);
  final BehaviorSubject<SynapseSyncStatus> _statusStream = BehaviorSubject<SynapseSyncStatus>.seeded(SynapseSyncStatus.idle);

  final Map<String, T> _rollbackBackup = {};
  
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  SynapseRepositoryImpl({
    required SynapseStorage<T> storage,
    required SynapseNetwork<T> network,
    required QueueStorage queueStorage,
    ConflictResolver<T>? resolver,
    SynapseConfig? config,
  })  : _storage = storage,
        _network = network,
        _queueStorage = queueStorage,
        _resolver = resolver ?? SmartMergeStrategy<T>(),
        _config = config ?? const SynapseConfig() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final localData = await _storage.readAll();
      _dataStream.add(localData);
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          _syncPendingItems();
        }
      });

      _syncPendingItems();
    } catch (e) {
      debugPrint("🔴 Synapse Init Error: $e");
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _dataStream.close();
    _statusStream.close();
  }

  @override
  Stream<List<T>> watchAll() => _dataStream.stream;

  @override
  Stream<SynapseSyncStatus> watchSyncStatus() => _statusStream.stream;

  @override
  Future<T?> getById(String id) async {
    // Try memory first
    try {
      return _dataStream.value.firstWhere((e) => e.id == id);
    } catch (_) {
      // Fallback to storage
      return await _storage.read(id);
    }
  }

  @override
  Future<void> add(T item) async {
    _updateLocalState(item);
    await _storage.write(item);
    await _addToQueue(item.id, SynapseOperationType.create, item.toJson());
    _syncPendingItems();
  }

  @override
  Future<void> update(T item) async {
    final currentList = _dataStream.value;
    final oldItem = currentList.firstWhere((e) => e.id == item.id, orElse: () => item);
    
    _rollbackBackup[item.id] = oldItem;
    _updateLocalState(item);
    await _storage.write(item);

    final delta = await compute(_calculateDeltaIsolated, {
      'old': oldItem.toJson(),
      'new': item.toJson(),
    });

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
    await _addToQueue(taskId, SynapseOperationType.upload, {
      'path': filePath, 
      'targetEntityId': targetEntityId
    });
    _syncPendingItems();
    return taskId; 
  }

  @override
  Future<List<T>> search(String query) async {
    if (query.isEmpty) return _dataStream.value;

    final rawData = _dataStream.value.map((e) => e.toJson()).toList();
    final matchingIds = await compute(_searchIsolated, {
      'data': rawData,
      'query': query,
    });

    final idsSet = matchingIds.toSet();
    return _dataStream.value.where((e) => idsSet.contains(e.id)).toList();
  }

  @override
  Future<List<T>> fetchPage(int page, {int pageSize = 20}) async {
    _statusStream.add(SynapseSyncStatus.syncing);
    try {
      final newItems = await _network.fetchAll(queryParams: {
        'page': page,
        'limit': pageSize,
      });

      for (var item in newItems) {
        await _storage.write(item);
      }

      final currentList = _dataStream.value;
      final mergedMap = {for (var item in currentList) item.id: item};
      for (var item in newItems) {
        mergedMap[item.id] = item;
      }
      
      _dataStream.add(mergedMap.values.toList());
      _statusStream.add(SynapseSyncStatus.idle);
      return newItems;

    } catch (e) {
      debugPrint('❌ Pagination failed: $e');
      _statusStream.add(SynapseSyncStatus.error);
      rethrow; 
    }
  }

  @override
  Future<void> refresh() async {
    _statusStream.add(SynapseSyncStatus.syncing);
    try {
      final remoteItems = await _network.fetchAll();
      final localItems = await _storage.readAll();

      final mergedItems = _resolver.resolve(localItems: localItems, remoteItems: remoteItems);

      await _storage.clear();
      for (var item in mergedItems) {
        await _storage.write(item);
      }

      _dataStream.add(mergedItems);
      _statusStream.add(SynapseSyncStatus.upToDate);
      await _syncPendingItems();

    } catch (e) {
      debugPrint('❌ Refresh failed: $e');
      _statusStream.add(SynapseSyncStatus.error);
    }
  }

  @override
  Future<List<QueueItem>> getQueueSnapshot() => _queueStorage.getAll();

  @override
  Future<void> clear() async {
    _dataStream.add([]);
    await _storage.clear();
    await _queueStorage.clear();
    _statusStream.add(SynapseSyncStatus.idle);
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
      retryCount: 0,
    );
    await _queueStorage.add(item);
  }

  Future<void> _performRollback(String entityId) async {
    if (_rollbackBackup.containsKey(entityId)) {
      final originalItem = _rollbackBackup[entityId]!;
      _updateLocalState(originalItem);
      await _storage.write(originalItem);
      _rollbackBackup.remove(entityId);
    } else {
      final currentList = [..._dataStream.value]..removeWhere((e) => e.id == entityId);
      _dataStream.add(currentList);
      await _storage.delete(entityId);
    }
  }

  Future<bool> _checkSyncConstraints() async {
    if (_config.syncPolicy == SynapseSyncPolicy.immediate) return true;
    if (_config.syncPolicy == SynapseSyncPolicy.manual) return false;

    // Check Connectivity
    if (_config.syncPolicy == SynapseSyncPolicy.wifiOnly || _config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final results = await _connectivity.checkConnectivity();
      final hasWifi = results.contains(ConnectivityResult.wifi);
      if (!hasWifi) return false;
    }

    // Fixed: Removed 'chargingOnly' check as it doesn't exist in Enum anymore.
    // Only checking for charging if policy is wifiAndCharging
    if (_config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final batteryState = await _battery.batteryState;
      if (batteryState != BatteryState.charging && batteryState != BatteryState.full) {
        return false;
      }
    }
    return true;
  }

  Future<void> _syncPendingItems() async {
    if (_isSyncing) return;
    
    final canSync = await _checkSyncConstraints();
    if (!canSync) {
      if (_statusStream.value != SynapseSyncStatus.error) {
         _statusStream.add(SynapseSyncStatus.offline);
      }
      return;
    }

    _isSyncing = true;
    _statusStream.add(SynapseSyncStatus.syncing);

    try {
      final queue = await _queueStorage.getAll();
      
      if (queue.isEmpty) {
        _statusStream.add(SynapseSyncStatus.idle);
        _isSyncing = false;
        return;
      }

      for (final item in queue) {
        if (item.retryCount >= _config.maxRetries) {
          await _performRollback(item.entityId);
          await _queueStorage.remove(item.id);
          _statusStream.add(SynapseSyncStatus.error);
          continue; 
        }

        try {
           await _executeOperation(item);
           await _queueStorage.remove(item.id);
           _rollbackBackup.remove(item.entityId);

        } catch (e) {
          bool isFatal = false;
          // Fixed: Removed strict null check to avoid 'operand cannot be null' warning
          if (e is NetworkException) {
            if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
              isFatal = true;
            }
          }

          if (isFatal) {
            await _performRollback(item.entityId);
            await _queueStorage.remove(item.id);
          } else {
            await _queueStorage.update(item.incrementRetry());
          }
          
          _statusStream.add(SynapseSyncStatus.error);
          break; 
        }
      }

    } catch (e) {
      _statusStream.add(SynapseSyncStatus.error);
    } finally {
      _isSyncing = false;
      final remaining = await _queueStorage.getAll();
      if (remaining.isEmpty && _statusStream.value != SynapseSyncStatus.error) {
        _statusStream.add(SynapseSyncStatus.idle);
      }
    }
  }

  Future<void> _executeOperation(QueueItem item) async {
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
  }
}

// Isolated functions remain same
Map<String, dynamic> _calculateDeltaIsolated(Map<String, dynamic> args) {
  final oldJson = args['old'] as Map<String, dynamic>;
  final newJson = args['new'] as Map<String, dynamic>;
  return DeltaSyncEngine.calculateDelta(oldJson, newJson);
}

List<String> _searchIsolated(Map<String, dynamic> args) {
  final data = (args['data'] as List).cast<Map<String, dynamic>>();
  final query = args['query'] as String;
  final results = SynapseSearchEngine.searchJson(data, query); 
  return results.map((e) => e['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
}