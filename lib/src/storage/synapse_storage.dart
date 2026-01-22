import '../core/synapse_entity.dart';

abstract class SynapseStorage<T extends SynapseEntity> {
  Future<List<T>> readAll();

  Future<T?> read(String id);

  Future<void> write(T item);

  Future<void> delete(String id);

  Future<void> clear();
  
  Future<void> close();
}