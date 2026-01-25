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
// 2. Storage Drivers (Included New Drivers)
// -----------------------------------------------------------------------------
export 'src/storage/synapse_storage.dart';
export 'src/storage/hive_storage.dart';
export 'src/storage/in_memory_storage.dart'; // Feature 16
export 'src/storage/drift_storage.dart';     // Feature 19 (Added)
export 'src/storage/isar_storage.dart';      // Feature 20 (Added)
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
// 4. Flutter UI Integration (Features 15 & 18)
// -----------------------------------------------------------------------------
export 'src/flutter/synapse_provider.dart';
export 'src/flutter/synapse_builder.dart';
export 'src/flutter/synapse_sync_indicator.dart';
export 'src/flutter/synapse_conflict_resolver.dart'; // Feature 18 (Added)
export 'src/flutter/synapse_adapters.dart';          // Feature 15 (Added)

// -----------------------------------------------------------------------------
// 5. The Facade (Easy Initialization)
// -----------------------------------------------------------------------------
import 'src/core/synapse_entity.dart';
import 'src/core/synapse_repository.dart';
import 'src/repository/synapse_repository_impl.dart';
import 'src/storage/synapse_storage.dart';
import 'src/network/synapse_network.dart';
import 'src/sync/queue_storage.dart';
import 'src/core/synapse_config.dart';

/// The Entry Point for SynapseLink.
/// Use this class to easily initialize your repositories.
class Synapse {
  /// Creates and initializes a [SynapseRepository] with a single call.
  /// 
  /// This implements the Facade Pattern to hide complexity.
  /// 
  /// [storage]: The storage driver (Hive, Drift, Isar, or Memory).
  /// [network]: The network service (Dio or Mock).
  /// [queue]: The queue storage strategy.
  /// [validator]: Optional validation hook (Feature 14).
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
}