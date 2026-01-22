import 'package:hive/hive.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import '../core/synapse_config.dart';
import 'synapse_storage.dart';
import 'synapse_migrator.dart';

class HiveStorage<T extends SynapseEntity> implements SynapseStorage<T> {
  final String boxName;
  final T Function(Map<String, dynamic>) fromJson;
  final SynapseMigrator? migrator;
  final SynapseConfig config;

  Box? _box;
  static const String _versionKey = '__schema_version__';
  
  static const String _kData = '__data__';
  static const String _kTimestamp = '__ts__';

  HiveStorage({
    required this.boxName,
    required this.fromJson,
    this.migrator,
    SynapseConfig? config,
  }) : config = config ?? const SynapseConfig();

  Future<void> initialize() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        _box = await Hive.openBox(boxName);
      }

      if (migrator != null) {
        await _performMigration();
      }
    } catch (e, stack) {
      throw StorageException(
          'Failed to initialize Hive box: $boxName', e, stack);
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
    
    final wrappedData = {
      _kData: entity.toJson(),
      _kTimestamp: DateTime.now().millisecondsSinceEpoch,
    };
    
    await box.put(entity.id, wrappedData);
  }

  @override
  Future<T?> read(String id) async {
    final box = await _getSafeBox();
    final rawData = box.get(id);

    if (rawData == null) return null;

    final mapData = Map<String, dynamic>.from(rawData);

    if (mapData.containsKey(_kData) && mapData.containsKey(_kTimestamp)) {
      final int timestamp = mapData[_kTimestamp];
      final DateTime savedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      if (DateTime.now().difference(savedAt) > config.cacheTtl) {
        if (config.clearExpiredCache) {
          await box.delete(id);
        }
        return null;
      }
      
      return fromJson(Map<String, dynamic>.from(mapData[_kData]));
    }

    return fromJson(mapData);
  }

  @override
  Future<List<T>> readAll() async {
    final box = await _getSafeBox();
    final List<T> results = [];
    final List<String> expiredKeys = [];

    for (var key in box.keys) {
      if (key == _versionKey) continue;

      final rawData = box.get(key);
      if (rawData is! Map) continue;

      final mapData = Map<String, dynamic>.from(rawData);

      if (mapData.containsKey(_kData) && mapData.containsKey(_kTimestamp)) {
         final int timestamp = mapData[_kTimestamp];
         final DateTime savedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

         if (DateTime.now().difference(savedAt) > config.cacheTtl) {
           if (config.clearExpiredCache) expiredKeys.add(key);
           continue;
         }
         
         results.add(fromJson(Map<String, dynamic>.from(mapData[_kData])));
      } else {
        results.add(fromJson(mapData));
      }
    }

    if (expiredKeys.isNotEmpty) {
      await box.deleteAll(expiredKeys);
    }

    return results;
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
    if (migrator != null) {
       await box.put(_versionKey, migrator!.currentVersion);
    }
  }

  @override
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }

  Future<void> _performMigration() async {
    final box = await _getSafeBox();
    final int storedVersion = box.get(_versionKey, defaultValue: 1);
    final int targetVersion = migrator!.currentVersion;

    if (storedVersion < targetVersion) {
      for (var key in box.keys) {
        if (key == _versionKey) continue;
        
        final rawData = box.get(key);
        if (rawData is Map) {
          Map<String, dynamic> dataToMigrate;
          bool isWrapped = false;
          int? timestamp;

          final mapData = Map<String, dynamic>.from(rawData);
          if (mapData.containsKey(_kData)) {
            dataToMigrate = Map<String, dynamic>.from(mapData[_kData]);
            timestamp = mapData[_kTimestamp];
            isWrapped = true;
          } else {
            dataToMigrate = mapData;
          }

          final upgraded = migrator!.migrate(
            dataToMigrate,
            storedVersion,
          );

          if (isWrapped) {
            await box.put(key, {
              _kData: upgraded,
              _kTimestamp: timestamp,
            });
          } else {
            await box.put(key, {
               _kData: upgraded,
               _kTimestamp: DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
      await box.put(_versionKey, targetVersion);
    }
  }
}