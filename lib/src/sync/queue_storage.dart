import 'queue_item.dart';

/// Abstract interface for persisting the Sync Queue.
/// This allows swapping between Hive, SQLite, or Memory for the queue itself.
abstract class QueueStorage {
  Future<void> add(QueueItem item);
  Future<void> remove(String id);
  Future<List<QueueItem>> getAll();
  Future<void> clear();
}

/// ✅ ADDED: The Missing Implementation
/// A simple in-memory queue for testing and demos.
class InMemoryQueueStorage implements QueueStorage {
  final List<QueueItem> _queue = [];

  @override
  Future<void> add(QueueItem item) async {
    _queue.add(item);
  }

  @override
  Future<void> remove(String id) async {
    _queue.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<QueueItem>> getAll() async {
    return List.from(_queue);
  }

  @override
  Future<void> clear() async {
    _queue.clear();
  }
}