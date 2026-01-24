import 'dart:async';
import 'package:synapse_link/src/core/synapse_operation.dart';
import 'synapse_entity.dart';
import '../sync/queue_item.dart';

/// The main entry point for interacting with data.
/// This repository abstracts the complexity of Local Storage vs Network.
abstract class SynapseRepository<T extends SynapseEntity> {
  /// Observes all items in real-time.
  Stream<List<T>> watchAll();

  /// Observes the current synchronization status.
  Stream<SynapseSyncStatus> watchSyncStatus();

  /// Adds a new item.
  Future<void> add(T item);

  /// Updates an existing item.
  Future<void> update(T item);

  /// Deletes an item by ID.
  Future<void> delete(String id);

  /// ✅ Fixed: Upload method signature to return a String (Task ID) 
  /// and accept an optional targetEntityId.
  Future<String> upload(String filePath, {String? targetEntityId});

  /// Searches the local data.
  Future<List<T>> search(String query);

  /// Forces a refresh from the remote server.
  Future<void> refresh();

  /// Gets a snapshot of the current pending operation queue.
  Future<List<QueueItem>> getQueueSnapshot();

  /// Clears all local data.
  Future<void> clear();
}