import '../core/synapse_entity.dart';

/// The abstract contract for Local Storage Drivers (Strategy Pattern).
/// Implementations can be Hive, SQLite (Drift), Isar, or In-Memory.
abstract class SynapseStorage<T extends SynapseEntity> {
  /// Reads all entities from the storage.
  Future<List<T>> readAll();

  /// Reads a single entity by its ID.
  Future<T?> read(String id);

  /// Writes (Create/Update) an entity to the storage.
  /// If [SynapseConfig.enableDataCompression] is true, the implementation
  /// handles compression internally.
  Future<void> write(T item);

  /// Deletes an entity by its ID.
  Future<void> delete(String id);

  /// Clears all data in this storage box/table.
  Future<void> clear();
  
  /// Closes the storage connection (if applicable).
  Future<void> close();
}