import 'synapse_storage.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';

class InMemoryStorage<T extends SynapseEntity> implements SynapseStorage<T> {
  final Map<String, T> _cache = {};


  @override
  Future<void> write(T entity) async {
    try {
      _cache[entity.id] = entity;
    } catch (e, stack) {
      throw StorageException('Failed to write to memory', e, stack);
    }
  }

  @override
  Future<T?> read(String id) async {
    return _cache[id];
  }

  @override
  Future<List<T>> readAll() async {
    return _cache.values.toList();
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  Future<void> close() async {
    _cache.clear();
  }
}