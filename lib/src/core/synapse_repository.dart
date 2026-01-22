import 'dart:async';
import 'package:synapse_link/src/core/synapse_operation.dart';

import 'synapse_entity.dart';
import '../sync/queue_item.dart';

abstract class SynapseRepository<T extends SynapseEntity> {
  // Streams
  Stream<List<T>> watchAll();
  Stream<SynapseSyncStatus> watchSyncStatus();

  // CRUD
  Future<void> add(T item);
  Future<void> update(T item);
  Future<void> delete(String id);

  // Upload (Updated Signature to match Implementation)
  Future<String> upload(String filePath, {String? targetEntityId});

  // Read
  Future<T?> getById(String id);
  Future<List<T>> search(String query);
  
  // Pagination
  Future<List<T>> fetchPage(int page, {int pageSize = 20});

  // Maintenance
  Future<void> refresh();
  Future<void> clear();
  
  // Added: This was missing in the interface causing the Dashboard error
  Future<List<QueueItem>> getQueueSnapshot(); 
}