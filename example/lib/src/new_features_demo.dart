import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synapse_link/synapse_link.dart';

// -----------------------------------------------------------------------------
// 1. نموذج البيانات (LogItem)
// يجب أن تكون المتغيرات non-nullable لتطابق المكتبة
// -----------------------------------------------------------------------------
class LogItem extends SynapseEntity {
  @override
  final String id;
  
  @override
  final DateTime updatedAt; // غير قابل للفراغ (مطلوب)
  
  @override
  final bool isDeleted;     // غير قابل للفراغ (مطلوب)

  final String action;
  final DateTime timestamp;

  LogItem({
    required this.id,
    required this.action,
    required this.timestamp,
    DateTime? updatedAt, 
    this.isDeleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now(); // تعيين قيمة افتراضية

  // دالة التحويل من JSON
  factory LogItem.fromJson(Map<String, dynamic> json) {
    return LogItem(
      id: json['id'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
  };
}

// -----------------------------------------------------------------------------
// 2. واجهة العرض (UI)
// -----------------------------------------------------------------------------
class NewFeaturesDemo extends StatefulWidget {
  const NewFeaturesDemo({super.key});

  @override
  State<NewFeaturesDemo> createState() => _NewFeaturesDemoState();
}

class _NewFeaturesDemoState extends State<NewFeaturesDemo> {
  late SynapseRepository<LogItem> _repo;
  final ScrollController _logController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  void _initRepository() {
    _repo = Synapse.create<LogItem>(
      storage: InMemoryStorage<LogItem>(),
      
      // ✅ التعديل هنا حسب طلبك: fromJson داخل الشبكة
      network: MockSynapseNetwork<LogItem>(
        fromJson: LogItem.fromJson, 
      ),
      
      queue: InMemoryQueueStorage(),
    );
  }

  void _spamUpdates() {
    for (int i = 0; i < 50; i++) {
      _repo.add(LogItem(
        id: "${DateTime.now().microsecondsSinceEpoch}_$i",
        action: 'Spam Event #$i',
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse 1.1 Features Lab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Secure Wipe',
            onPressed: () async {
              await Synapse.wipeAndReset();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Secure Wipe Executed')),
                );
                setState(() {
                  _initRepository();
                });
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _spamUpdates,
                  icon: const Icon(Icons.speed),
                  label: const Text("Test Throttling"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Synapse.schedulePeriodicSync(frequency: const Duration(minutes: 15));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Background Task Scheduled')),
                    );
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text("Background Sync"),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<LogItem>>(
              stream: _repo.watchAll(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.action),
                      subtitle: Text(item.timestamp.toIso8601String()),
                      leading: const Icon(Icons.bolt, size: 16),
                      dense: true,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 150,
            color: Colors.black87,
            child: StreamBuilder<String>(
              stream: Synapse.logStream,
              builder: (context, snapshot) {
                final logs = Synapse.logs.reversed.toList();
                return ListView.builder(
                  controller: _logController,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        logs[index],
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Courier'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}