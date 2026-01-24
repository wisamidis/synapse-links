import 'package:hive/hive.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_storage.dart';
import 'synapse_migrator.dart';
import '../core/synapse_config.dart';

/// A robust implementation of local storage using Hive (NoSQL).
/// Supports Schema Migration and Data Expiry (TTL).
class HiveStorage<T extends SynapseEntity> implements SynapseStorage<T> {
  /// The name of the Hive box (table).
  final String boxName;

  /// Factory function to convert JSON to Entity.
  final T Function(Map<String, dynamic>) fromJson;

  /// Helper class to handle version upgrades.
  final SynapseMigrator? migrator;

  /// Configuration for TTL and expiry policies.
  final SynapseConfig? config;

  Box? _box;
  static const String _versionKey = '__schema_version__';

  HiveStorage({
    required this.boxName,
    required this.fromJson,
    this.migrator,
    this.config,
  });

  Future<void> initialize() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        _box = await Hive.openBox(boxName);
      }

      // Handle Schema Migration
      if (migrator != null) {
        await _performMigration();
      }

      // Handle Data Expiry (TTL) safely
      if (config != null && config!.clearExpiredCache && config!.cacheTtl != null) {
        await _clearExpiredData();
      }

    } catch (e, stack) {
      throw StorageException('Failed to initialize Hive box: $boxName', e, stack);
    }
  }

  Future<Box> _getSafeBox() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
    return _box!;
  }

  @override
  Future<void> write(T entity) async {
    final box = await _getSafeBox();
    await box.put(entity.id, entity.toJson());
  }

  @override
  Future<T?> read(String id) async {
    final box = await _getSafeBox();
    final data = box.get(id);
    if (data != null) {
      return fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  @override
  Future<List<T>> readAll() async {
    final box = await _getSafeBox();
    return box.values
        .where((v) => v is Map && !v.containsKey(_versionKey))
        .map((v) => fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getSafeBox();
    await box.delete(id);
  }

  @override
  Future<void> clear() async {
    final box = await _getSafeBox();
    await box.clear();
  }

  /// ✅ Fixed: Renamed from 'dispose' to 'close' to match the abstract class.
  @override
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }

  /// Handles upgrading data structure when the app version changes.
  Future<void> _performMigration() async {
    final box = await _getSafeBox();
    final int storedVersion = box.get(_versionKey, defaultValue: 1);
    final int targetVersion = migrator!.currentVersion;

    if (storedVersion < targetVersion) {
      for (var key in box.keys) {
        if (key == _versionKey) continue;
        final data = box.get(key);
        if (data is Map) {
          final upgraded = migrator!.migrate(
            Map<String, dynamic>.from(data), 
            storedVersion,
          );
          await box.put(key, upgraded);
        }
      }
      await box.put(_versionKey, targetVersion);
    }
  }

  /// Clear Expired Data (TTL)
  Future<void> _clearExpiredData() async {
    final box = await _getSafeBox();
    final expiryThreshold = DateTime.now().subtract(config!.cacheTtl!);

    final keysToDelete = <String>[];

    for (var key in box.keys) {
      if (key == _versionKey) continue;

      final data = box.get(key);
      if (data is Map && data.containsKey('updatedAt')) {
        try {
          final updatedAt = DateTime.parse(data['updatedAt']);
          if (updatedAt.isBefore(expiryThreshold)) {
            keysToDelete.add(key);
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }
}