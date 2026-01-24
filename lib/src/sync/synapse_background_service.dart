import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/synapse_operation.dart';
import '../network/synapse_network.dart';
import 'hive_queue_storage.dart';
import 'queue_item.dart'; 

/// Task and unique identity constants for the background synchronization.
const String _kSynapseSyncTask = "synapse.sync.task";
const String _kUniquePeriodicTask = "synapse_periodic_sync_id";

/// Manages background synchronization using the Workmanager package.
/// 
/// This service runs in a separate Isolate to handle offline sync tasks 
/// even when the application is terminated or running in the background.
class SynapseBackgroundService {
  
  /// Initializes the WorkManager engine.
  /// 
  /// [callbackDispatcher] must be a top-level or static function.
  static Future<void> initialize(Function callbackDispatcher) async {
    await Workmanager().initialize(
      callbackDispatcher,
      // NOTE: isInDebugMode is deprecated in v0.9.0+. 
      // The package now handles logs automatically based on build mode.
    );
  }

  /// Registers a periodic sync task to run in the background.
  /// 
  /// - Frequency: Every 15 minutes (Minimum allowed by Android OS).
  /// - Constraints: Requires internet connectivity and healthy battery levels.
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _kUniquePeriodicTask,
      _kSynapseSyncTask,
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      // ✅ FINAL FIX: In Workmanager 0.9.0, for periodic tasks, the parameter 
      // name is 'existingWorkPolicy' but the required TYPE is 'ExistingPeriodicWorkPolicy'.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  /// The main synchronization logic executed by the background isolate.
  /// 
  /// [networkBuilder]: A factory function providing a fresh [SynapseNetwork] instance.
  static Future<void> executeBackgroundSync(
    SynapseNetwork Function() networkBuilder,
  ) async {
    try {
      // Initialize Hive for the background isolate thread
      await Hive.initFlutter();
      
      final network = networkBuilder();
      final queueStorage = HiveQueueStorage();
      
      // Explicitly typed List to prevent "Unused Import" warnings
      final List<QueueItem> queue = await queueStorage.getAll();

      if (queue.isEmpty) {
        debugPrint("✅ SynapseLink: Sync queue is empty.");
        return;
      }

      debugPrint("🔄 SynapseLink: Processing ${queue.length} background items...");

      for (QueueItem item in queue) {
        // Dead Letter Queue: Skip items that failed more than 3 times
        if (item.retryCount > 3) {
          debugPrint("⚠️ SynapseLink: Max retries reached for item ${item.id}.");
          continue; 
        }

        bool isSuccess = false;
        try {
          switch (item.type) {
            case SynapseOperationType.create:
              await network.create(item.payload);
              break;
            case SynapseOperationType.update:
              await network.update(item.entityId, item.payload);
              break;
            case SynapseOperationType.delete:
              await network.delete(item.entityId);
              break;
            case SynapseOperationType.upload:
              final String? path = item.payload['path'];
              if (path != null) {
                await network.uploadFile(path);
              }
              break;
          }
          isSuccess = true;
        } catch (e) {
          debugPrint("❌ SynapseLink: Task failed for ${item.id}: $e");
          isSuccess = false;
        }

        if (isSuccess) {
          await queueStorage.remove(item.id);
        } else {
          // Increment retry count and update the queue persistence
          await queueStorage.add(item.incrementRetry());
        }
      }
    } catch (e) {
      debugPrint("💀 SynapseLink: Fatal background execution error: $e");
    }
  }
}