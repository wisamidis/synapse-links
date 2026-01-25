import 'package:flutter/material.dart';
import 'package:synapse_link/synapse_link.dart';

// =============================================================================
// 1. DATA MODEL DEFINITION (VERSION 1.0.4)
// =============================================================================
/// Represents a Todo Task entity.
/// 
/// Extends [SynapseEntity] to utilize the offline-sync logic provided by the library.
class TodoItem extends SynapseEntity {
  final String title;
  final bool isDone;

  @override
  final String id;
  
  @override
  final bool isDeleted;
  
  @override
  final DateTime updatedAt;

  /// Constructor for TodoItem.
  /// 
  /// The [updatedAt] parameter is optional in the constructor and 
  /// defaults to the current time if not provided.
  TodoItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.isDeleted = false,
    DateTime? updatedAt, // Named parameter defined here
  }) : updatedAt = updatedAt ?? DateTime.now(); // Initializer list usage

  /// Serialization: Converts Entity to JSON Map.
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'isDeleted': isDeleted,
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Deserialization: Creates Entity from JSON Map.
  /// 
  /// This method now correctly matches the named parameter in the constructor.
  static TodoItem fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      isDone: json['isDone'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      // Fixed: Passing value to the correctly defined named parameter 'updatedAt'
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

// =============================================================================
// 2. FEATURE SHOWCASE UI
// =============================================================================
class FeatureShowcase extends StatefulWidget {
  const FeatureShowcase({super.key});

  @override
  State<FeatureShowcase> createState() => _FeatureShowcaseState();
}

class _FeatureShowcaseState extends State<FeatureShowcase> {
  /// Repository instance using the SynapseLink logic core.
  late SynapseRepository<TodoItem> _repository;
  
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  /// Initializes the repository with all the new 1.0.4 features.
  void _initRepository() {
    
    // Feature 14: Pre-Sync Validation Hook
    void todoValidator(TodoItem item) {
      if (item.title.trim().isEmpty) {
        throw Exception("Validation Error: Title cannot be empty.");
      }
    }

    // Facade Initialization Pattern
    _repository = Synapse.create<TodoItem>(
      storage: HiveStorage<TodoItem>(
        boxName: 'todos_v1_0_4_stable', 
        fromJson: (json) => TodoItem.fromJson(json),
      ),
      network: MockSynapseNetwork<TodoItem>(
        fromJson: (json) => TodoItem.fromJson(json),
      ),
      queue: InMemoryQueueStorage(),
      validator: todoValidator,
      config: const SynapseConfig(
        enableDataCompression: true, // Feature 17: Transparent Data Compression
        syncPolicy: SynapseSyncPolicy.immediate,
      ),
    );
  }

  /// Adds a new item while respecting the validation logic.
  void _addTodo() async {
    try {
      final newItem = TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _controller.text,
      );
      
      await _repository.add(newItem);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Feature 18: Conflict Resolution UI Widget
  void _simulateConflict() {
    final local = TodoItem(id: '1', title: 'Local Data');
    final remote = TodoItem(id: '1', title: 'Server Data');

    showDialog(
      context: context,
      builder: (ctx) => SynapseConflictResolver<TodoItem>(
        localItem: local,
        remoteItem: remote,
        onResolve: (_) => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse 1.0.4 Stable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on), 
            tooltip: 'Test Conflict Resolution',
            onPressed: _simulateConflict
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Task Title', 
                      border: OutlineInputBorder(),
                      helperText: 'Validation hook prevents empty submissions',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addTodo, 
                  icon: const Icon(Icons.add_circle, size: 32, color: Colors.blue),
                ),
              ],
            ),
          ),
          
          // Feature 15: Built-in Reactive Adapter
          Expanded(
            child: SynapseReactiveBuilder<TodoItem>(
              repository: _repository,
              builder: (context, items) {
                if (items.isEmpty) {
                   return const Center(
                     child: Text("No Tasks Yet.\nLogic-heavy, UI-light architecture."),
                   );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      leading: const Icon(Icons.check_box_outline_blank),
                      title: Text(item.title),
                      subtitle: Text("Updated At: ${item.updatedAt.hour}:${item.updatedAt.minute}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _repository.delete(item.id),
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