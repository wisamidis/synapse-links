import 'package:flutter/material.dart';
import '../core/synapse_entity.dart';
import '../sync/queue_item.dart';
import 'synapse_provider.dart';

/// Admin dashboard to monitor the sync queue and force actions.
class SynapseDashboard<T extends SynapseEntity> extends StatefulWidget {
  const SynapseDashboard({super.key});

  @override
  State<SynapseDashboard<T>> createState() => _SynapseDashboardState<T>();
}

class _SynapseDashboardState<T extends SynapseEntity> extends State<SynapseDashboard<T>> {
  List<QueueItem> _queueItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay slightly to ensure context is ready
    Future.microtask(() => _refreshQueue());
  }

  Future<void> _refreshQueue() async {
    if (!mounted) return;
    
    final repo = SynapseProvider.of<T>(context);
    setState(() => _isLoading = true);
    
    try {
      // Note: getQueueSnapshot is mainly for debugging
      final items = await repo.getQueueSnapshot();
      if (mounted) {
        setState(() {
          _queueItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmNuke(BuildContext context, dynamic repo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ DANGER ZONE'),
        content: const Text(
          'This will delete ALL local data and clear the sync queue.\n\n'
          'Unsynced changes will be lost forever. Are you sure?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('NUKE EVERYTHING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
       await repo.clear();
       _refreshQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = SynapseProvider.of<T>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQueue,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatCard(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Offline Queue (Pending Actions)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _queueItems.isEmpty
                    ? const Center(child: Text('Queue is empty. All synced! ✅'))
                    : ListView.builder(
                        itemCount: _queueItems.length,
                        itemBuilder: (context, index) {
                          final item = _queueItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.retryCount > 0 ? Colors.orange : Colors.blue,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item.type.name.toUpperCase()),
                            subtitle: Text(
                              'ID: ${item.entityId}\nRetries: ${item.retryCount}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              item.createdAt.toIso8601String().split('T').last.split('.').first,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _confirmNuke(context, repo),
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text('NUKE CACHE & QUEUE', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Pending Items', style: TextStyle(color: Colors.grey)),
                Text('${_queueItems.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
             Column(
              children: [
                const Text('Status', style: TextStyle(color: Colors.grey)),
                Text(_isLoading ? 'Loading...' : 'Ready', 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: _isLoading ? Colors.blue : Colors.green
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}