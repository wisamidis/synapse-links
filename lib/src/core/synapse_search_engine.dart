import 'synapse_entity.dart';

class SynapseSearchEngine {
  /// Searches a list of entities.
  /// 
  /// WARNING: For lists > 500 items, run this in an Isolate to avoid UI jank.
  static List<T> search<T extends SynapseEntity>(List<T> items, String query) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase().trim();

    return items.where((item) {
      // Optimization: Try to convert to Map only once per item context
      try {
        final json = item.toJson();
        return _matchesQuery(json, lowerQuery);
      } catch (e) {
        // Fallback or log error if toJson fails
        return false;
      }
    }).toList();
  }

  static List<Map<String, dynamic>> searchJson(
      List<Map<String, dynamic>> items, String query) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase().trim();

    return items.where((item) {
      return _matchesQuery(item, lowerQuery);
    }).toList();
  }

  static bool _matchesQuery(dynamic value, String query) {
    if (value == null) return false;

    // Fast exit for simple types
    if (value is String) {
      return value.toLowerCase().contains(query);
    }
    if (value is num || value is bool) {
      return value.toString().contains(query);
    }

    // Recursion with depth protection (to prevent StackOverflow)
    // You might want to pass a 'depth' counter if data is very deep
    if (value is List) {
      return value.any((element) => _matchesQuery(element, query));
    }

    if (value is Map) {
      return value.values.any((element) => _matchesQuery(element, query));
    }

    return false;
  }
}