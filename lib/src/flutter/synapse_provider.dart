import 'package:flutter/material.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_repository.dart';
import '../repository/synapse_repository_impl.dart';
import '../storage/synapse_storage.dart';
import '../network/synapse_network.dart';
import '../core/synapse_config.dart';
import '../sync/queue_storage.dart'; // ✅ Added import for QueueStorage interface

/// The Glue that holds the SynapseLink ecosystem together.
/// 
/// This [StatefulWidget] initializes the [SynapseRepository] and injects it 
/// into the widget tree using an [InheritedWidget] for efficient access.
class SynapseProvider<T extends SynapseEntity> extends StatefulWidget {
  /// The local storage engine (e.g., HiveStorage).
  final SynapseStorage<T> storage;

  /// The remote network layer (e.g., DioSynapseNetwork).
  final SynapseNetwork<T> network;

  /// The offline queue storage (e.g., HiveQueueStorage or InMemoryQueueStorage).
  final QueueStorage queueStorage;

  /// Configuration for sync policies and cache TTL.
  final SynapseConfig config;

  /// The root widget of your application or module.
  final Widget child;

  const SynapseProvider({
    super.key,
    required this.storage,
    required this.network,
    required this.queueStorage, // ✅ Now strictly required and flexible
    this.config = const SynapseConfig(),
    required this.child,
  });

  /// Static helper to find the [SynapseRepository] instance in the widget tree.
  /// 
  /// Usage: `final repo = SynapseProvider.of<MyModel>(context);`
  static SynapseRepository<T> of<T extends SynapseEntity>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_SynapseInherited<T>>();
    if (provider == null) {
      throw Exception(
        'SynapseProvider<$T> not found in context. '
        'Ensure you wrap your app with SynapseProvider<$T> at the top level.',
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
    // ✅ Initialize the repository using the provided storage engines.
    // We pass the queueStorage from the widget to maintain flexibility.
    _repository = SynapseRepositoryImpl<T>(
      storage: widget.storage,
      network: widget.network,
      queueStorage: widget.queueStorage, // ✅ Fixed: No longer hardcoded
      config: widget.config,
    );
  }

  @override
  void dispose() {
    // ✅ Properly cleanup streams and resources to prevent memory leaks.
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wraps the child in a private InheritedWidget to provide the repository.
    return _SynapseInherited<T>(
      repository: _repository,
      child: widget.child,
    );
  }
}

/// Private [InheritedWidget] that stores the repository instance.
class _SynapseInherited<T extends SynapseEntity> extends InheritedWidget {
  final SynapseRepository<T> repository;

  const _SynapseInherited({
    super.key,
    required this.repository,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SynapseInherited<T> oldWidget) {
    // The repository instance remains constant; updates are handled via streams.
    return false;
  }
}