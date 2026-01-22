import 'package:flutter/foundation.dart';

@immutable
abstract class SynapseEntity {
  const SynapseEntity();

  String get id;
  
  // Non-nullable logic is preferred for sync, but if null, 
  // it implies "not synced yet" or "local only".
  DateTime? get updatedAt; 
  
  bool get isDeleted;

  Map<String, dynamic> toJson();

  // Helper to ensure we can identify if item needs sync
  bool get needsSync => updatedAt == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SynapseEntity &&
        other.id == id &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, isDeleted);
}