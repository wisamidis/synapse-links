import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/synapse_operation.dart';
import '../network/synapse_network.dart';
import 'hive_queue_storage.dart';
import 'queue_item.dart'; 

const String _kSynapseSyncTask = "synapse.sync.task";
const String _kUniquePeriodicTask = "synapse_periodic_sync_id";

/// Manages background synchronization using the Workmanager package.
class SynapseBackgroundService {
  
  static Future<void> initialize(Function callbackDispatcher) async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  /// Feature 25: Scheduled Background Heartbeat
  static Future<void> registerPeriodicTask({Duration frequency = const Duration(minutes: 15)}) async {
    // Android limits min frequency to 15 mins.
    final effectiveFreq = frequency.inMinutes < 15 ? const Duration(minutes: 15) : frequency;
    
    debugPrint("Synapse: Registering background task every ${effectiveFreq.inMinutes} mins");
    
    await Workmanager().registerPeriodicTask(
      _kUniquePeriodicTask,
      _kSynapseSyncTask,
      frequency: effectiveFreq, 
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  /// Feature 22 Helper: Cancel tasks on wipe
  static Future<void> cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName(_kUniquePeriodicTask);
  }

  static Future<void> executeBackgroundSync(
    SynapseNetwork Function() networkBuilder,
  ) async {
    try {
      await Hive.initFlutter();
      
      final network = networkBuilder();
      final queueStorage = HiveQueueStorage();
      
      final List<QueueItem> queue = await queueStorage.getAll();

      if (queue.isEmpty) {
        debugPrint("✅ SynapseLink [BG]: Queue empty. Sleeping.");
        return;
      }

      debugPrint("🔄 SynapseLink [BG]: Processing ${queue.length} items...");

      for (QueueItem item in queue) {
        if (item.retryCount > 3) {
          debugPrint("⚠️ SynapseLink [BG]: Skipping dead item ${item.id}.");
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
          debugPrint("❌ SynapseLink [BG]: Failed ${item.id}: $e");
          isSuccess = false;
        }

        if (isSuccess) {
          await queueStorage.remove(item.id);
        } else {
          await queueStorage.add(item.incrementRetry());
        }
      }
    } catch (e) {
      debugPrint("💀 SynapseLink [BG]: Fatal error: $e");
    }
  }
}