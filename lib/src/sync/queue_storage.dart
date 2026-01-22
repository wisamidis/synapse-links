import 'queue_item.dart';

/// Abstract interface for persisting the sync queue.
/// 
/// Implementations can be Hive, SQLite, or In-Memory.
abstract class QueueStorage {
  /// Retrieves all pending items, sorted by creation time.
  Future<List<QueueItem>> getAll();

  /// Adds a new item to the queue.
  Future<void> add(QueueItem item);

  /// Updates an existing item (e.g., incrementing retry count).
  Future<void> update(QueueItem item); // Added

  /// Removes an item from the queue after successful sync.
  Future<void> remove(String id);

  /// Wipes the entire queue.
  Future<void> clear();
}