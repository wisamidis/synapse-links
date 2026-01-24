import 'package:synapse_link/synapse_link.dart';

/// A simple ToDo entity implementing [SynapseEntity].
class TodoItem extends SynapseEntity {
  @override
  final String id;

  @override
  final DateTime? updatedAt;

  @override
  final bool isDeleted;

  final String title;
  final bool isCompleted;

  // ✅ FIXED: Constructor must be const for @immutable classes
  const TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isDeleted = false,
    this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  TodoItem copyWith({String? title, bool? isCompleted, bool? isDeleted}) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: DateTime.now(),
    );
  }
}