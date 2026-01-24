/// SynapseLink: The Enterprise-Grade Offline Sync Library for Flutter.
/// 
/// This library provides a complete solution for:
/// 1. Local Data Persistence (Hive / SQLite).
/// 2. Robust Network Synchronization (Dio / REST).
/// 3. Offline-First Capability with Smart Queue Management.
/// 4. Optimistic UI Updates & Deep Conflict Resolution.
library synapse_link;

// -----------------------------------------------------------------------------
// 1. Core Module (The Data Contract)
// -----------------------------------------------------------------------------
/// These files define the fundamental data structures and configuration options.
/// Developers must interact with these to set up their data models.
export 'src/core/synapse_entity.dart';      // Base class for all data models.
export 'src/core/synapse_config.dart';      // Configuration for Sync Policies & TTL.
export 'src/core/synapse_repository.dart';  // The main interface for CRUD operations.
export 'src/core/synapse_exception.dart';   // Custom exceptions for error handling.
export 'src/core/synapse_operation.dart';   // Enum defining operation types (Create, Update, etc.).

// -----------------------------------------------------------------------------
// 2. Storage Module (Local Persistence)
// -----------------------------------------------------------------------------
/// Interfaces and Implementations for local data storage.
/// Developers choose the storage engine that suits their needs.
export 'src/storage/synapse_storage.dart';   // Abstract storage contract.
export 'src/storage/hive_storage.dart';      // High-performance NoSQL implementation.
export 'src/storage/in_memory_storage.dart'; // Volatile storage for testing.
export 'src/storage/synapse_migrator.dart';  // Helper for database schema upgrades.

// -----------------------------------------------------------------------------
// 3. Network Module (Remote Communication)
// -----------------------------------------------------------------------------
/// Handlers for communicating with remote APIs.
/// Developers instantiate these to connect the app to the backend.
export 'src/network/synapse_network.dart';      // Abstract network contract.
export 'src/network/dio_synapse_network.dart';  // Robust REST implementation using Dio.
export 'src/network/mock_synapse_network.dart'; // Simulation tool for offline development.
export 'src/network/synapse_response.dart';     // Standardized API response wrapper.

// -----------------------------------------------------------------------------
// 4. Sync Module (Queue & Conflict Resolution)
// -----------------------------------------------------------------------------
/// Tools for managing data consistency and offline requests.
/// NOTE: Internal engines (like DeltaSync) are hidden to keep the API clean.
export 'src/sync/conflict_resolver.dart';       // Interface for custom merge logic.
export 'src/sync/smart_merge_strategy.dart';    // Default intelligent merge implementation.
export 'src/sync/queue_item.dart';              // Represents a pending sync task.
export 'src/sync/queue_storage.dart';           // Interface for queue persistence.
export 'src/sync/synapse_background_service.dart'; // Entry point for background tasks.

// -----------------------------------------------------------------------------
// 5. Flutter Integration (UI Layer)
// -----------------------------------------------------------------------------
/// Widgets and Providers to integrate SynapseLink into the Flutter Widget Tree.
export 'src/flutter/synapse_provider.dart';       // The main Dependency Injection widget.
export 'src/flutter/synapse_builder.dart';        // A StreamBuilder wrapper for reactive UI.
export 'src/flutter/synapse_sync_indicator.dart'; // Visual indicator for sync status.
export 'src/flutter/synapse_dashboard.dart';      // Debug dashboard for monitoring data.