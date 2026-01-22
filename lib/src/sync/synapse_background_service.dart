import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:synapse_link/src/core/synapse_operation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Assuming you have a way to instantiate your network layer independently
import '../network/synapse_network.dart';
import 'hive_queue_storage.dart';

const String _kSynapseSyncTask = "synapse.sync.task";

/// Manages background synchronization using Workmanager.
/// 
/// This runs in a separate Isolate, so dependency injection must be handled carefully.
class SynapseBackgroundService {
  
  static Future<void> initialize(Function callbackDispatcher) async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "synapse_periodic_sync_id",
      _kSynapseSyncTask,
      // 15 minutes is the minimum allowed by Android OS
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// The core logic to run in the background.
  /// 
  /// [networkBuilder]: A function that returns an initialized SynapseNetwork instance.
  /// We pass a builder because we cannot pass an existing instance across Isolates.
  static Future<void> executeBackgroundSync(
    SynapseNetwork Function() networkBuilder,
  ) async {
    try {
      // Initialize Hive for the background isolate
      await Hive.initFlutter();
      
      final network = networkBuilder();
      final queueStorage = HiveQueueStorage();
      final queue = await queueStorage.getAll();

      if (queue.isEmpty) return;

      debugPrint("🔄 Synapse BG: Processing ${queue.length} items...");

      for (var item in queue) {
        // Skip items that failed too many times (Dead Letter Queue logic)
        if (item.retryCount > 3) {
          debugPrint("⚠️ Skipping item ${item.id} after 3 failed attempts.");
          continue; 
          // Optional: Move to a 'failed_jobs' box instead of ignoring
        }

        bool success = false;
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
              if (item.payload['path'] != null) {
                // Warning: File paths might be invalid in background if app cleared cache
                await network.uploadFile(item.payload['path']);
              }
              break;
          }
          success = true;
        } catch (e) {
          debugPrint("❌ Sync Error for ${item.id}: $e");
          success = false;
        }

        if (success) {
          await queueStorage.remove(item.id);
        } else {
          // Increment retry count so we don't try forever instantly
          await queueStorage.update(item.incrementRetry());
        }
      }
    } catch (e) {
      debugPrint("💀 Fatal Background Error: $e");
    }
  }
}