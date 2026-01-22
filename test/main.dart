import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:synapse_link/synapse_link.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// 1. THE DATA MODEL
// -----------------------------------------------------------------------------
/// A simple Task entity that extends [SynapseEntity].
/// This represents the data we want to sync.
@immutable
class Task extends SynapseEntity {
  @override
  final String id;
  final String title;
  final bool isCompleted;
  
  @override
  final DateTime? updatedAt;
  
  @override
  final bool isDeleted;

  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.updatedAt,
    this.isDeleted = false,
  });

  // Factory to create a new Task easily
  factory Task.create(String title) {
    return Task(
      id: const Uuid().v4(), // Generate unique ID
      title: title,
      updatedAt: DateTime.now(),
    );
  }

  // Required: Convert from JSON (from Storage/Network)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  // Required: Convert to JSON (for Storage/Network)
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  // Helper: Create a copy with modified fields (Immutable Pattern)
  Task copyWith({
    String? title,
    bool? isCompleted,
    bool? isDeleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: DateTime.now(), // Always update timestamp on change
    );
  }
}

// -----------------------------------------------------------------------------
// 2. MAIN APP ENTRY POINT
// -----------------------------------------------------------------------------
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage (Required by Synapse's default storage)
  await Hive.initFlutter();

  runApp(const SynapseExampleApp());
}

class SynapseExampleApp extends StatelessWidget {
  const SynapseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // 3. SYNAPSE PROVIDER SETUP
    // -------------------------------------------------------------------------
    // Wrap your app (or the part that needs data) with SynapseProvider.
    return SynapseProvider<Task>(
      // A. Local Storage: We use HiveStorage provided by the library.
      storage: HiveStorage<Task>(
        boxName: 'synapse_tasks_box',
        fromJson: Task.fromJson,
      ),
      
      // B. Network Layer: We use MockSynapseNetwork for this example.
      // In production, use DioSynapseNetwork(baseUrl: '...', ...).
      network: const MockSynapseNetwork<Task>(
        fromJson: Task.fromJson,
        delay:  Duration(milliseconds: 800), // Simulate network latency
        simulateErrors: false, // Set to true to test offline/error behavior
      ),
      
      // C. Configuration: Define sync policies (WiFi only, Immediate, etc.)
      config: const SynapseConfig(
        syncPolicy: SynapseSyncPolicy.immediate, // Sync as soon as possible
        clearExpiredCache: false,
      ),
      
      child: MaterialApp(
        title: 'Synapse Link Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const TaskListScreen(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. THE UI SCREEN
// -----------------------------------------------------------------------------
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the repository to perform actions
    final repository = SynapseProvider.of<Task>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse Tasks'),
        actions: [
          // A built-in widget to show sync status (Online, Syncing, Error)
          const SynapseSyncIndicator<Task>(),
          
          // Button to open the Admin Dashboard
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Open Sync Dashboard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SynapseDashboard<Task>(),
                ),
              );
            },
          ),
        ],
      ),
      
      // 5. SYNAPSE BUILDER (Reactive UI)
      body: SynapseBuilder<Task>(
        // Placeholder when list is empty
        emptyPlaceholder: _buildEmptyState(),
        
        // Error handler
        errorBuilder: (context, error) => Center(child: Text('Error: $error')),
        
        // The Data Builder
        builder: (context, tasks, status) {
          // Filter out deleted items (Soft Delete handling)
          final activeTasks = tasks.where((t) => !t.isDeleted).toList();

          if (activeTasks.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = activeTasks[index];
              return _buildTaskItem(context, repository, task);
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, repository),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tasks yet.\nAdd one and watch it sync!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, SynapseRepository<Task> repo, Task task) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // DELETE Action
        repo.delete(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted locally & queued for sync')),
        );
      },
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              // UPDATE Action
              final updatedTask = task.copyWith(isCompleted: value);
              repo.update(updatedTask);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            'ID: ${task.id.substring(0, 8)}...',
            style: const TextStyle(fontSize: 10),
          ),
          trailing: const Icon(Icons.cloud_queue, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, SynapseRepository<Task> repo) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // CREATE Action
                final newTask = Task.create(controller.text);
                repo.add(newTask);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
