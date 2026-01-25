import 'queue_item.dart';
import 'queue_storage.dart';

class InMemoryQueueStorage implements QueueStorage {
  final List<QueueItem> _queue = [];

  @override
  Future<List<QueueItem>> getAll() async {
    return List.from(_queue);
  }

  @override
  Future<void> add(QueueItem item) async {
    _queue.add(item);
  }

  Future<void> update(QueueItem item) async {
    final index = _queue.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _queue[index] = item;
    }
  }

  @override
  Future<void> remove(String id) async {
    _queue.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async {
    _queue.clear();
  }
}