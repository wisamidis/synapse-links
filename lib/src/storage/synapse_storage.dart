import '../core/synapse_entity.dart';

/// The abstract contract for Local Storage Drivers (Strategy Pattern).
/// Implementations can be Hive, SQLite (Drift), Isar, or In-Memory.
abstract class SynapseStorage<T extends SynapseEntity> {
  /// Reads all entities from the storage.
  Future<List<T>> readAll();

  /// Reads a single entity by its ID.
  Future<T?> read(String id);

  /// Writes (Create/Update) an entity to the storage.
  /// Implementations MUST handle DateTime/Complex types if not handled by Entity.
  Future<void> write(T item);

  /// Deletes an entity by its ID.
  Future<void> delete(String id);

  /// Feature 22: Secure Wipe Support
  /// This must completely destroy all data in the table/box.
  Future<void> clear();
  
  /// Closes the storage connection (if applicable).
  Future<void> close();
}