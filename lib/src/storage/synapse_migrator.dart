abstract class SynapseMigrator {
  int get currentVersion;

  Map<String, dynamic> migrate(Map<String, dynamic> oldData, int oldVersion);
}

class NoOpMigrator implements SynapseMigrator {
  @override
  int get currentVersion => 1;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> oldData, int oldVersion) {
    return oldData;
  }
}

class MigrationChain implements SynapseMigrator {
  final int _version;
  final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
      _migrations;

  MigrationChain(this._version, this._migrations);

  @override
  int get currentVersion => _version;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> oldData, int oldVersion) {
    var migratedData = Map<String, dynamic>.from(oldData);

    for (var v = oldVersion; v < _version; v++) {
      final migrationStep = _migrations[v];
      if (migrationStep != null) {
        migratedData = migrationStep(migratedData);
      }
    }
    return migratedData;
  }
}