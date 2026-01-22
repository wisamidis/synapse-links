import '../core/synapse_entity.dart';

abstract class ConflictResolver<T extends SynapseEntity> {
  List<T> resolve({
    required List<T> localItems,
    required List<T> remoteItems,
  });
}