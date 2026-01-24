import 'queue_item.dart';

/// Abstract contract for storing the offline request queue.
abstract class QueueStorage {
  /// Adds a new item to the queue.
  Future<void> add(QueueItem item);

  /// Removes an item from the queue by ID.
  Future<void> remove(String id);

  /// ✅ Added: Updates an existing item in the queue.
  Future<void> update(QueueItem item);

  /// Retrieves all pending items in the queue.
  Future<List<QueueItem>> getAll();

  /// Clears the entire queue.
  Future<void> clear();
}