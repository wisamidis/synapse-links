import 'package:flutter/material.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_repository.dart';
import '../repository/synapse_repository_impl.dart';
import '../storage/synapse_storage.dart';
import '../network/synapse_network.dart';
import '../core/synapse_config.dart';
import '../sync/hive_queue_storage.dart';

/// The Glue that holds everything together.
/// Injects the Repository into the widget tree.
class SynapseProvider<T extends SynapseEntity> extends StatefulWidget {
  final SynapseStorage<T> storage;
  final SynapseNetwork<T> network;
  final SynapseConfig config;
  final Widget child;

  const SynapseProvider({
    super.key,
    required this.storage,
    required this.network,
    this.config = const SynapseConfig(),
    required this.child,
  });

  /// Helper to find the repository in the context.
  static SynapseRepository<T> of<T extends SynapseEntity>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_SynapseInherited<T>>();
    if (provider == null) {
      throw Exception(
        'SynapseProvider<$T> not found in context. '
        'Make sure to wrap your widget tree with SynapseProvider<$T> at the top level.',
      );
    }
    return provider.repository;
  }

  @override
  State<SynapseProvider<T>> createState() => _SynapseProviderState<T>();
}

class _SynapseProviderState<T extends SynapseEntity> extends State<SynapseProvider<T>> {
  late SynapseRepositoryImpl<T> _repository;

  @override
  void initState() {
    super.initState();
    // Initialize the repository implementation
    _repository = SynapseRepositoryImpl<T>(
      storage: widget.storage,
      network: widget.network,
      queueStorage: HiveQueueStorage(),
      config: widget.config,
    );
  }

  @override
  void dispose() {
    // Cleanup resources (streams, connections)
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SynapseInherited<T>(
      repository: _repository,
      child: widget.child,
    );
  }
}

class _SynapseInherited<T extends SynapseEntity> extends InheritedWidget {
  final SynapseRepository<T> repository;

  const _SynapseInherited({
    super.key,
    required this.repository,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SynapseInherited<T> oldWidget) {
    // We don't need to rebuild dependents if the repo instance stays the same.
    // The streams inside the repo handle the updates.
    return false;
  }
}