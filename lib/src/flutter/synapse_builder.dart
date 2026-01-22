import 'package:flutter/material.dart';
import 'package:synapse_link/src/core/synapse_operation.dart';
import '../core/synapse_entity.dart';
import 'synapse_provider.dart';

/// A wrapper widget that listens to both data changes and sync status.
/// 
/// Automatically updates the UI when local data changes or when sync status updates.
class SynapseBuilder<T extends SynapseEntity> extends StatefulWidget {
  final Widget Function(
      BuildContext context, List<T> items, SynapseSyncStatus status) builder;
  final Widget? emptyPlaceholder;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;

  const SynapseBuilder({
    Key? key,
    required this.builder,
    this.emptyPlaceholder,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<SynapseBuilder<T>> createState() => _SynapseBuilderState<T>();
}

class _SynapseBuilderState<T extends SynapseEntity> extends State<SynapseBuilder<T>> {
  // Cache the stream to prevent recreating it on every build
  late Stream<List<T>> _dataStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We initialize the stream here because we need access to 'context' via Provider
    _dataStream = SynapseProvider.of<T>(context).watchAll();
  }

  @override
  Widget build(BuildContext context) {
    final repository = SynapseProvider.of<T>(context);

    return StreamBuilder<List<T>>(
      stream: _dataStream,
      builder: (context, dataSnapshot) {
        if (dataSnapshot.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, dataSnapshot.error);
          }
          return Center(
            child: Text(
              'Synapse Error: ${dataSnapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!dataSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = dataSnapshot.data!;

        // Nested StreamBuilder for Sync Status
        return StreamBuilder<SynapseSyncStatus>(
          stream: repository.watchSyncStatus(),
          initialData: SynapseSyncStatus.idle,
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data ?? SynapseSyncStatus.idle;

            if (items.isEmpty && widget.emptyPlaceholder != null) {
              return widget.emptyPlaceholder!;
            }

            return widget.builder(context, items, status);
          },
        );
      },
    );
  }
}