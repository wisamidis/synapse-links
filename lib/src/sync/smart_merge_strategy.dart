import '../core/synapse_entity.dart';
import 'conflict_resolver.dart';

/// A smart strategy to merge local and remote data, handling conflicts
/// based on timestamps (Last-Write-Wins) and preserving nested relationships.
class SmartMergeStrategy<T extends SynapseEntity> implements ConflictResolver<T> {
  
  @override
  List<T> resolve({required List<T> localItems, required List<T> remoteItems}) {
    // Map local items by ID for O(1) lookup
    final Map<String, T> mergedMap = {for (var item in localItems) item.id: item};

    for (var remoteItem in remoteItems) {
      if (mergedMap.containsKey(remoteItem.id)) {
        final localItem = mergedMap[remoteItem.id]!;
        
        // ✅ Feature 12: Smart comparison. Prefer remote if it's newer.
        if (_shouldPreferRemote(localItem, remoteItem)) {
          mergedMap[remoteItem.id] = remoteItem;
        }
      } else {
        // New item from server
        mergedMap[remoteItem.id] = remoteItem;
      }
    }

    return mergedMap.values.toList();
  }

  /// Determines if the remote item should overwrite the local item.
  bool _shouldPreferRemote(T local, T remote) {
    try {
      final localMap = local.toJson();
      final remoteMap = remote.toJson();

      // Check for 'updatedAt' timestamp
      if (localMap.containsKey('updatedAt') && remoteMap.containsKey('updatedAt')) {
         final localTime = DateTime.parse(localMap['updatedAt']);
         final remoteTime = DateTime.parse(remoteMap['updatedAt']);
         
         // If remote is newer, return true
         return remoteTime.isAfter(localTime);
      }
    } catch (_) {
      // If parsing fails, default to Remote as Source of Truth
      return true;
    }
    // Default fallback
    return true;
  }
}