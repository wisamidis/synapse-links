/// Utility engine to calculate the difference between two JSON objects.
/// Used to send only changed fields (PATCH) instead of full objects (PUT).
class DeltaSyncEngine {
  
  /// Feature 24: Auto-Type Conversion
  /// Recursively converts complex Dart objects (DateTime, Enums) to JSON-safe primitives.
  static Map<String, dynamic> autoConvertTypes(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = {};
    data.forEach((key, value) {
      converted[key] = _convertValue(value);
    });
    return converted;
  }

  static dynamic _convertValue(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return autoConvertTypes(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map((e) => _convertValue(e)).toList();
    }
    // Handle specific Flutter types if needed, e.g. Color(0xFF000000) -> int
    // if (value.toString().startsWith("Color(")) return value.value; 
    
    return value;
  }

  /// Returns a map containing only the fields that changed in [newData] compared to [oldData].
  static Map<String, dynamic> calculateDelta(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    // Ensure types are primitive before comparison
    final oldSafe = autoConvertTypes(oldData);
    final newSafe = autoConvertTypes(newData);

    final Map<String, dynamic> delta = {};

    for (final key in newSafe.keys) {
      if (!oldSafe.containsKey(key)) {
        delta[key] = newSafe[key];
        continue;
      }

      final oldValue = oldSafe[key];
      final newValue = newSafe[key];

      if (oldValue is Map<String, dynamic> &&
          newValue is Map<String, dynamic>) {
        final nestedDelta = calculateDelta(oldValue, newValue);
        if (nestedDelta.isNotEmpty) {
          delta[key] = nestedDelta;
        }
        continue;
      }

      if (_hasChanged(oldValue, newValue)) {
        delta[key] = newValue;
      }
    }

    return delta;
  }

  static bool _hasChanged(dynamic oldVal, dynamic newVal) {
    if (oldVal is List && newVal is List) {
      if (oldVal.length != newVal.length) return true;
      return oldVal.toString() != newVal.toString();
    }
    return oldVal != newVal;
  }
}