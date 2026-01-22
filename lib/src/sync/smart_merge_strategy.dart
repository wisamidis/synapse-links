import '../core/synapse_entity.dart';
import 'conflict_resolver.dart';

/// A conflict resolution strategy that merges local and remote lists.
///
/// Rules:
/// 1. If an item exists in both lists -> Keep the one with the latest `updatedAt`.
/// 2. If an item is only local -> Keep it (it hasn't synced yet).
/// 3. If an item is only remote -> Keep it (it was created on another device).
class SmartMergeStrategy<T extends SynapseEntity> implements ConflictResolver<T> {
  
  @override
  List<T> resolve({
    required List<T> localItems,
    required List<T> remoteItems,
  }) {
    final Map<String, T> remoteMap = {
      for (var item in remoteItems) item.id: item
    };

    final List<T> mergedList = [];
    final Set<String> processedIds = {};

    // 1. Process local items (handle conflicts or keep local-only)
    for (final localItem in localItems) {
      final remoteItem = remoteMap[localItem.id];

      if (remoteItem != null) {
        // Conflict detected: Resolve based on timestamp
        final selectedItem = _resolveConflict(localItem, remoteItem);
        mergedList.add(selectedItem);
        processedIds.add(localItem.id);
      } else {
        // FIXED: Keep local-only items (e.g., created while offline)
        mergedList.add(localItem);
        processedIds.add(localItem.id);
      }
    }

    // 2. Add remaining remote items (new data from server)
    for (final remoteItem in remoteItems) {
      if (!processedIds.contains(remoteItem.id)) {
        mergedList.add(remoteItem);
      }
    }

    return mergedList;
  }

  /// Compares timestamps to decide the winner (Last-Write-Wins).
  T _resolveConflict(T local, T remote) {
    // We strictly use the entity's updatedAt property.
    // If updatedAt is null, we assume it's a new local item or corrupted remote item.
    
    if (local.updatedAt == null) return local; // Local is likely newer/unsynced
    if (remote.updatedAt == null) return local; // Fallback

    if (local.updatedAt!.isAfter(remote.updatedAt!)) {
      return local;
    }

    return remote;
  }
}