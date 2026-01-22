import 'package:flutter/material.dart';
import 'package:synapse_link/src/core/synapse_operation.dart';
import '../core/synapse_entity.dart';
import 'synapse_provider.dart';

/// A small widget to visualize the current sync state.
class SynapseSyncIndicator<T extends SynapseEntity> extends StatelessWidget {
  final Color idleColor;
  final Color syncingColor;
  final Color errorColor;
  final Color offlineColor;
  final Color upToDateColor;

  const SynapseSyncIndicator({
    super.key,
    this.idleColor = Colors.grey,
    this.syncingColor = Colors.blue,
    this.errorColor = Colors.red,
    this.offlineColor = Colors.orange,
    this.upToDateColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final repository = SynapseProvider.of<T>(context);

    return StreamBuilder<SynapseSyncStatus>(
      stream: repository.watchSyncStatus(),
      initialData: SynapseSyncStatus.idle,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SynapseSyncStatus.idle;

        switch (status) {
          case SynapseSyncStatus.syncing:
            return _buildIcon(Icons.sync, syncingColor, isSpinning: true);
          
          case SynapseSyncStatus.offline:
            return _buildIcon(Icons.wifi_off, offlineColor);
          
          case SynapseSyncStatus.error:
            return _buildIcon(Icons.error_outline, errorColor);
            
          case SynapseSyncStatus.upToDate:
            return _buildIcon(Icons.cloud_done, upToDateColor);
            
          case SynapseSyncStatus.idle:
          return _buildIcon(Icons.cloud_queue, idleColor);
        }
      },
    );
  }

  Widget _buildIcon(IconData icon, Color color, {bool isSpinning = false}) {
    if (isSpinning) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(icon, color: color, size: 24),
    );
  }
}