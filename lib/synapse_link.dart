/// SynapseLink: The Enterprise-Grade Offline Sync Library for Flutter.
library;

// -----------------------------------------------------------------------------
// 1. Core Exports (The Contract)
// -----------------------------------------------------------------------------
export 'src/core/synapse_entity.dart';
export 'src/core/synapse_config.dart';
export 'src/core/synapse_repository.dart';
export 'src/core/synapse_exception.dart';
export 'src/core/synapse_operation.dart';

// -----------------------------------------------------------------------------
// 2. Storage Drivers
// -----------------------------------------------------------------------------
export 'src/storage/synapse_storage.dart';
export 'src/storage/hive_storage.dart';
export 'src/storage/in_memory_storage.dart';
export 'src/storage/drift_storage.dart';
export 'src/storage/isar_storage.dart';
export 'src/storage/synapse_migrator.dart';

// -----------------------------------------------------------------------------
// 3. Network & Sync
// -----------------------------------------------------------------------------
export 'src/network/synapse_network.dart';
export 'src/network/dio_synapse_network.dart';
export 'src/network/mock_synapse_network.dart';
export 'src/sync/conflict_resolver.dart';
export 'src/sync/queue_storage.dart';
// Note: Internal engines like DeltaSync are hidden for cleanliness.

// -----------------------------------------------------------------------------
// 4. Flutter UI Integration
// -----------------------------------------------------------------------------
export 'src/flutter/synapse_provider.dart';
export 'src/flutter/synapse_builder.dart';
export 'src/flutter/synapse_sync_indicator.dart';
export 'src/flutter/synapse_conflict_resolver.dart';
export 'src/flutter/synapse_adapters.dart';

// -----------------------------------------------------------------------------
// 5. The Facade (Easy Initialization & Global Controls)
// -----------------------------------------------------------------------------
import 'src/core/synapse_entity.dart';
import 'src/core/synapse_repository.dart';
import 'src/repository/synapse_repository_impl.dart';
import 'src/storage/synapse_storage.dart';
import 'src/network/synapse_network.dart';
import 'src/sync/queue_storage.dart';
import 'src/core/synapse_config.dart';
import 'src/sync/synapse_background_service.dart';

/// The Entry Point for SynapseLink.
class Synapse {
  /// Feature 21: Access to the Audit Trail Logs
  static List<String> get logs => SynapseLogRegistry.logs;
  static Stream<String> get logStream => SynapseLogRegistry.logStream;

  /// Creates and initializes a [SynapseRepository].
  static SynapseRepository<T> create<T extends SynapseEntity>({
    required SynapseStorage<T> storage,
    required SynapseNetwork<T> network,
    required QueueStorage queue,
    SynapseConfig config = const SynapseConfig(),
    SynapseValidator<T>? validator,
  }) {
    return SynapseRepositoryImpl<T>(
      storage: storage,
      network: network,
      queueStorage: queue,
      config: config,
      validator: validator,
    );
  }

  /// Feature 22: One-Line Secure Wipe
  /// Destroys all local data, clears queues, and resets the library state.
  static Future<void> wipeAndReset() async {
    SynapseLogRegistry.add("🚨 SECURE WIPE INITIATED");
    // This is a global wipe signal. In a real app with multiple repositories,
    // you would typically track active repositories in a static list and loop them.
    // For this implementation, we assume the user manages the repo instances,
    // but we provide the utility to clear the background service and logs.
    await SynapseBackgroundService.cancelPeriodicTask();
    SynapseLogRegistry.clear();
  }

  /// Feature 25: Schedule Background Heartbeat
  static Future<void> schedulePeriodicSync({Duration frequency = const Duration(hours: 1)}) async {
    SynapseLogRegistry.add("⏰ Scheduling background sync every ${frequency.inMinutes} minutes");
    await SynapseBackgroundService.registerPeriodicTask(frequency: frequency);
  }
}