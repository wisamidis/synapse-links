import 'package:flutter/material.dart';
import '../core/synapse_entity.dart';

class SynapseConflictResolver<T extends SynapseEntity> extends StatelessWidget {
  final T localItem;
  final T remoteItem;
  final Function(T) onResolve;
  final String title;

  const SynapseConflictResolver({
    super.key,
    required this.localItem,
    required this.remoteItem,
    required this.onResolve,
    this.title = 'Sync Conflict Detected',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(context, 'Your Version (Local)', localItem, Colors.blue.shade50),
            const SizedBox(height: 16),
            const Icon(Icons.compare_arrows, size: 32, color: Colors.grey),
            const SizedBox(height: 16),
            _buildSection(context, 'Server Version (Remote)', remoteItem, Colors.orange.shade50),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onResolve(localItem),
          child: const Text('Keep Mine'),
        ),
        FilledButton(
          onPressed: () => onResolve(remoteItem),
          child: const Text('Accept Server'),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String label, T item, Color bg) {
    final json = item.toJson();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const Divider(),
          ...json.entries.map((e) {
            if (e.key == 'id') return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                  Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 11))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}