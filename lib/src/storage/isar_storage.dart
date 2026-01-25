import 'package:isar/isar.dart';
import '../core/synapse_entity.dart';
import 'synapse_storage.dart';

/// Feature 20: Isar (High-Performance NoSQL) Storage Driver.
/// Provides blazing fast local storage for SynapseLink.
class IsarStorage<T extends SynapseEntity, I> implements SynapseStorage<T> {
  final Isar isar;
  final IsarCollection<I> collection;

  /// Converters between Synapse Entity and Isar Object
  final I Function(T entity) toIsar;
  final T Function(I isarObject) fromIsar;

  /// Helper to extract ID from Isar Object (Isar uses int or String fast hash)
  final int Function(String id) idEncoder;

  IsarStorage({
    required this.isar,
    required this.collection,
    required this.toIsar,
    required this.fromIsar,
    // Isar requires an integer ID.
    // Default encoder uses hashCode, but user should provide stable logic if needed.
    int Function(String id)? idEncoder,
  }) : idEncoder = idEncoder ?? ((id) => id.hashCode);

  @override
  Future<void> write(T entity) async {
    final isarObj = toIsar(entity);
    await isar.writeTxn(() async {
      await collection.put(isarObj);
    });
  }

  @override
  Future<T?> read(String id) async {
    final intId = idEncoder(id);
    final result = await collection.get(intId);
    return result != null ? fromIsar(result) : null;
  }

  @override
  Future<List<T>> readAll() async {
    final results = await collection.where().findAll();
    return results.map(fromIsar).toList();
  }

  @override
  Future<void> delete(String id) async {
    final intId = idEncoder(id);
    await isar.writeTxn(() async {
      await collection.delete(intId);
    });
  }

  @override
  Future<void> clear() async {
    await isar.writeTxn(() async {
      await collection.clear();
    });
  }

  @override
  Future<void> close() async {
    // Isar instance is usually global, so we might not want to close it entirely.
    // Leaving optional implementation.
  }
}
