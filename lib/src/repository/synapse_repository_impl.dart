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

// --- Feature 21: Built-in Log Registry ---
class SynapseLogRegistry {
  static final List<String> _logs = [];
  static final BehaviorSubject<String> _logSubject = BehaviorSubject();

  static List<String> get logs => List.unmodifiable(_logs);
  static Stream<String> get logStream => _logSubject.stream;

  static void add(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final logEntry = "[$timestamp] $message";
    _logs.add(logEntry);
    if (_logs.length > 1000) _logs.removeAt(0); // Keep last 1000 logs
    _logSubject.add(logEntry);
    debugPrint("SynapseLog: $logEntry");
  }

  static void clear() {
    _logs.clear();
  }
}

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
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    try {
      SynapseLogRegistry.add("Initializing Repository for ${T.toString()}");
      final localData = await _storage.readAll();
      _dataStream.add(localData);
      _initialized = true;

      // Feature: TTL Check (Placeholder)
      if (_config.clearExpiredCache) {
         // Logic implementation
      }

      _syncPendingItems();
    } catch (e) {
      SynapseLogRegistry.add("❌ Init Error: $e");
    }
  }

  void dispose() {
    _dataStream.close();
    _statusStream.close();
  }
  
  void resumeSync() {
    SynapseLogRegistry.add("🔐 Auth refreshed. Resuming sync...");
    _isPausedForAuth = false;
    _statusStream.add(SynapseSyncStatus.idle);
    _syncPendingItems();
  }

  @override
  Stream<List<T>> watchAll() {
    // Feature 23: Stream Throttling & Debouncing
    // Prevents UI Jank by limiting updates to once every 50ms.
    return _dataStream.stream.throttleTime(
      const Duration(milliseconds: 50),
      trailing: true,
      leading: true,
    );
  }

  @override
  Stream<SynapseSyncStatus> watchSyncStatus() => _statusStream.stream;

  @override
  Future<void> add(T item) async {
    if (_validator != null) {
      try {
        _validator!(item);
      } catch (e) {
        throw SynapseException('Validation failed: $e');
      }
    }

    _updateLocalState(item);
    // Feature 24: Auto-Type Conversion happens inside storage write usually,
    // but we ensure the item is ready.
    await _storage.write(item);
    
    // Feature 24: Ensure payload is primitive-safe
    final jsonPayload = DeltaSyncEngine.autoConvertTypes(item.toJson());
    
    await _addToQueue(item.id, SynapseOperationType.create, jsonPayload);
    _syncPendingItems();
  }

  @override
  Future<void> update(T item) async {
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

    // Feature 24 applied in Delta calculation
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
      SynapseLogRegistry.add("☁️ Fetching fresh data from server...");
      final remoteItems = await _network.fetchAll();
      final localItems = _dataStream.value;
      final mergedItems = _resolver.resolve(localItems: localItems, remoteItems: remoteItems);

      await _storage.clear();
      for (var item in mergedItems) {
        await _storage.write(item);
      }

      _dataStream.add(mergedItems);
      SynapseLogRegistry.add("✅ Refresh successful. Items: ${mergedItems.length}");
      await _syncPendingItems();

      if (_statusStream.value != SynapseSyncStatus.error && _statusStream.value != SynapseSyncStatus.offline) {
        _statusStream.add(SynapseSyncStatus.idle);
      }
    } catch (e) {
      SynapseLogRegistry.add("❌ Refresh Failed: $e");
      if (e is NetworkException && e.statusCode == 401) {
         _isPausedForAuth = true;
         _statusStream.add(SynapseSyncStatus.error);
      } else {
         _statusStream.add(SynapseSyncStatus.error);
      }
    }
  }

  @override
  Future<List<QueueItem>> getQueueSnapshot() => _queueStorage.getAll();

  @override
  Future<void> clear() async {
    // Feature 22: Part of the secure wipe
    _dataStream.add([]);
    await _storage.clear();
    await _queueStorage.clear();
    SynapseLogRegistry.add("🧹 Repository Cleared");
  }

  // Feature 22 helper: Public wipe access
  Future<void> secureWipe() async {
      await clear();
      _rollbackBackup.clear();
      _isInitialized = false; // Force re-init if reused
  }
  
  // Setter to fix the _initialized usage in secureWipe if needed, or just set var.
  set _isInitialized(bool val) => _initialized = val;

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
    SynapseLogRegistry.add("📥 Queued ${type.name} for $entityId");
  }

  Future<void> _performRollback(String entityId) async {
    if (_rollbackBackup.containsKey(entityId)) {
      final originalItem = _rollbackBackup[entityId]!;
      _updateLocalState(originalItem);
      await _storage.write(originalItem);
      _rollbackBackup.remove(entityId);
      SynapseLogRegistry.add("↩️ Rolled back item $entityId");
    } else {
      final currentList = [..._dataStream.value]..removeWhere((e) => e.id == entityId);
      _dataStream.add(currentList);
      await _storage.delete(entityId);
      SynapseLogRegistry.add("↩️ Rolled back creation of $entityId");
    }
  }

  Future<bool> _checkSyncConstraints() async {
    if (_config.syncPolicy == SynapseSyncPolicy.immediate) return true;

    if (_config.syncPolicy == SynapseSyncPolicy.wifiOnly || _config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final result = await _connectivity.checkConnectivity();
      if (!result.contains(ConnectivityResult.wifi)) {
          SynapseLogRegistry.add("⏸️ Sync paused: Waiting for WiFi");
          return false;
      }
    }

    if (_config.syncPolicy == SynapseSyncPolicy.chargingOnly || _config.syncPolicy == SynapseSyncPolicy.wifiAndCharging) {
      final batteryState = await _battery.batteryState;
      if (batteryState != BatteryState.charging && batteryState != BatteryState.full) {
          SynapseLogRegistry.add("⏸️ Sync paused: Waiting for Charger");
          return false;
      }
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
      SynapseLogRegistry.add("🚀 Starting Sync: ${queue.length} items pending");

      // Batch Optimization
      if (queue.length >= 5) { 
          final batchCreateItems = queue.where((i) => i.type == SynapseOperationType.create).toList();
          if (batchCreateItems.length >= 2) {
            try {
              final payloads = batchCreateItems.map((e) => e.payload).toList();
              await _network.batchCreate(payloads);
              SynapseLogRegistry.add("📦 Batch synced ${batchCreateItems.length} items");
              for(var item in batchCreateItems) {
                 await _queueStorage.remove(item.id);
                 _rollbackBackup.remove(item.entityId);
              }
              queue = await _queueStorage.getAll();
            } catch (e) {
               SynapseLogRegistry.add("⚠️ Batch failed, falling back to single: $e");
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
          SynapseLogRegistry.add("✅ Synced ${item.type.name} for ${item.entityId}");
        
        } catch (e) {
          SynapseLogRegistry.add("❌ Sync Error for ${item.id}: $e");
          
          if (e is NetworkException && e.statusCode == 401) {
             _isPausedForAuth = true;
             SynapseLogRegistry.add("⛔ Auth 401. Pausing.");
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
        SynapseLogRegistry.add("🏁 Sync Complete. Queue empty.");
      }
    } finally {
      _isSyncing = false;
    }
  }
}