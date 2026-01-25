import 'synapse_storage.dart';
import '../core/synapse_entity.dart';

class InMemoryStorage<T extends SynapseEntity> implements SynapseStorage<T> {
  final Map<String, T> _memoryMap = {};

  @override
  Future<void> write(T entity) async {
    _memoryMap[entity.id] = entity;
  }

  @override
  Future<T?> read(String id) async {
    return _memoryMap[id];
  }

  @override
  Future<List<T>> readAll() async {
    return _memoryMap.values.toList();
  }

  @override
  Future<void> delete(String id) async {
    _memoryMap.remove(id);
  }

  @override
  Future<void> clear() async {
    _memoryMap.clear();
  }

  @override
  Future<void> close() async {
    _memoryMap.clear();
  }
}