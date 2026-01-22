/// SynapseLink: A high-performance, offline-first data synchronization library for Flutter.
/// 
/// This library provides a robust architecture for managing local data persistence,
/// optimistic UI updates, and background synchronization with remote servers.
library synapse_link;

// --- Core Module ---
/// Core models, configurations, and base repository interfaces.
export 'src/core/synapse_entity.dart';
export 'src/core/synapse_config.dart';
export 'src/core/synapse_repository.dart';
export 'src/core/synapse_exception.dart';
export 'src/core/synapse_operation.dart'; // Ensure this matches your file name

// --- Storage Module ---
/// Local persistence layer implementations including Hive and In-Memory storage.
export 'src/storage/synapse_storage.dart';
export 'src/storage/hive_storage.dart';
export 'src/storage/in_memory_storage.dart';
export 'src/storage/synapse_migrator.dart';

// --- Network Module ---
/// Communication layer handlers for REST APIs (Dio) and testing (Mock).
export 'src/network/synapse_network.dart';
export 'src/network/dio_synapse_network.dart';
export 'src/network/mock_synapse_network.dart';

// --- Sync Module ---
/// Offline queue management and background synchronization services.
export 'src/sync/queue_storage.dart';
export 'src/sync/hive_queue_storage.dart';
export 'src/sync/in_memory_queue_storage.dart';
export 'src/sync/queue_item.dart';
export 'src/sync/synapse_background_service.dart';

// --- Flutter Integration ---
/// Widgets and providers for seamless Flutter UI state management and monitoring.
export 'src/flutter/synapse_provider.dart';
export 'src/flutter/synapse_builder.dart';
export 'src/flutter/synapse_sync_indicator.dart';
export 'src/flutter/synapse_dashboard.dart';