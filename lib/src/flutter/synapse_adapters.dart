import 'dart:async';
import 'package:flutter/material.dart';
import '../core/synapse_repository.dart';
import '../core/synapse_entity.dart';

class SynapseStreamAdapter<T extends SynapseEntity> {
  final SynapseRepository<T> repository;

  SynapseStreamAdapter(this.repository);

  Stream<List<T>> get asStream => repository.watchAll();

  ValueNotifier<List<T>> toValueNotifier() {
    final notifier = ValueNotifier<List<T>>([]);
    repository.watchAll().listen((data) {
      notifier.value = data;
    });
    return notifier;
  }
}

class SynapseReactiveBuilder<T extends SynapseEntity> extends StatelessWidget {
  final SynapseRepository<T> repository;
  final Widget Function(BuildContext, List<T>) builder;
  final Widget? loading;
  final Widget? error;

  const SynapseReactiveBuilder({
    super.key,
    required this.repository,
    required this.builder,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: repository.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return error ?? Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return loading ?? const Center(child: CircularProgressIndicator());
        }
        return builder(context, snapshot.data!);
      },
    );
  }
}