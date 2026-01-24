import 'package:flutter/material.dart';
import 'package:synapse_link/synapse_link.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'lib/todo_item.dart';

/// In-Memory Queue implementation for the Example app.
class InMemoryQueueStorage implements QueueStorage {
  static final List<QueueItem> _items = [];
  
  const InMemoryQueueStorage();

  @override
  Future<void> add(QueueItem item) async => _items.add(item);
  
  @override
  Future<void> remove(String id) async => _items.removeWhere((i) => i.id == id);
  
  @override
  Future<void> update(QueueItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }
  
  @override
  Future<List<QueueItem>> getAll() async => List.from(_items);
  
  @override
  Future<void> clear() async => _items.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // ✅ FIXED: Added 'const' to the MockSynapseNetwork constructor (Address main.dart:41)
  const network = MockSynapseNetwork<TodoItem>(
    fromJson: TodoItem.fromJson,
    delay: Duration(milliseconds: 800),
  );

  final storage = HiveStorage<TodoItem>(
    boxName: 'example_todos',
    fromJson: TodoItem.fromJson,
  );

  runApp(MyApp(network: network, storage: storage));
}

class MyApp extends StatelessWidget {
  final SynapseNetwork<TodoItem> network;
  final SynapseStorage<TodoItem> storage;

  const MyApp({super.key, required this.network, required this.storage});

  @override
  Widget build(BuildContext context) {
    return SynapseProvider<TodoItem>(
      network: network,
      storage: storage,
      queueStorage: const InMemoryQueueStorage(),
      config: const SynapseConfig(
        syncPolicy: SynapseSyncPolicy.immediate,
      ),
      // ✅ FIXED: Added 'const' to MaterialApp and simplified theme for const compatibility
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        home: TodoScreen(),
      ),
    );
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SynapseProvider.of<TodoItem>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SynapseLink Live Demo"),
        actions: const [SynapseSyncIndicator()],
      ),
      body: SynapseBuilder<TodoItem>(
        builder: (context, items, status) {
          if (items.isEmpty) {
            return const Center(child: Text("No data. Click + to add."));
          }
          
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Checkbox(
                  value: item.isCompleted,
                  onChanged: (v) => repo.update(item.copyWith(isCompleted: v)),
                ),
                title: Text(item.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => repo.delete(item.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          repo.add(TodoItem(
            id: const Uuid().v4(),
            title: "Task ${DateTime.now().second}",
            updatedAt: DateTime.now(),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}