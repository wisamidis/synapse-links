/// Utility engine to calculate the difference between two JSON objects.
/// Used to send only changed fields (PATCH) instead of full objects (PUT).
class DeltaSyncEngine {
  
  /// Returns a map containing only the fields that changed in [newData] compared to [oldData].
  static Map<String, dynamic> calculateDelta(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final Map<String, dynamic> delta = {};

    for (final key in newData.keys) {
      // Case 1: New field added
      if (!oldData.containsKey(key)) {
        delta[key] = newData[key];
        continue;
      }

      final oldValue = oldData[key];
      final newValue = newData[key];

      // Case 2: Recursively check nested maps
      if (oldValue is Map<String, dynamic> &&
          newValue is Map<String, dynamic>) {
        final nestedDelta = calculateDelta(oldValue, newValue);
        if (nestedDelta.isNotEmpty) {
          delta[key] = nestedDelta;
        }
        continue;
      }

      // Case 3: Value changed
      if (_hasChanged(oldValue, newValue)) {
        delta[key] = newValue;
      }
    }

    return delta;
  }

  static bool _hasChanged(dynamic oldVal, dynamic newVal) {
    // Handle List comparisons specifically
    if (oldVal is List && newVal is List) {
      if (oldVal.length != newVal.length) return true;
      // Note: This simple toString check is fast but assumes order matters.
      // For deeper list comparison, a deep equality check is needed.
      return oldVal.toString() != newVal.toString();
    }
    
    return oldVal != newVal;
  }
}