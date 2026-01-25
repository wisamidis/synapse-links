import 'dart:async';
import 'package:hive/hive.dart';
import 'queue_item.dart';
import 'queue_storage.dart';

/// Implementation of QueueStorage using Hive (NoSQL local DB).
class HiveQueueStorage implements QueueStorage {
  static const String _boxName = 'synapse_queue_box';
  Box? _box;

  /// Lazy loader for the Hive box.
  Future<Box> get _db async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<List<QueueItem>> getAll() async {
    try {
      final box = await _db;
      final rawList = box.values.toList();
      
      final items = rawList.map((e) {
        // Safe casting to prevent runtime errors
        if (e is Map) {
          return QueueItem.fromMap(Map<String, dynamic>.from(e));
        }
        return null;
      }).whereType<QueueItem>().toList();

      // Sort by creation date to ensure FIFO (First In, First Out)
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    } catch (e) {
      // Return empty list on corruption to avoid blocking the app
      return [];
    }
  }

  @override
  Future<void> add(QueueItem item) async {
    final box = await _db;
    await box.put(item.id, item.toMap());
  }

  Future<void> update(QueueItem item) async {
    final box = await _db;
    await box.put(item.id, item.toMap());
  }

  @override
  Future<void> remove(String id) async {
    final box = await _db;
    await box.delete(id);
  }

  @override
  Future<void> clear() async {
    final box = await _db;
    await box.clear();
  }
}