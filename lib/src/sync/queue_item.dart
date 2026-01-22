
import 'package:synapse_link/src/core/synapse_operation.dart';

/// Represents a single operation waiting to be synced to the server.
/// 
/// This class is immutable and serializable to be stored in local database.
class QueueItem {
  final String id;
  final String entityId;
  final SynapseOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount; // Added: To track how many times we tried to sync this

  const QueueItem({
    required this.id,
    required this.entityId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0, // Default is 0
  });

  /// Creates a copy of the item with incremented retry count.
  QueueItem incrementRetry() {
    return QueueItem(
      id: id,
      entityId: entityId,
      type: type,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount + 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'typeIndex': type.index,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'],
      entityId: map['entityId'],
      type: SynapseOperationType.values[map['typeIndex']],
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      retryCount: map['retryCount'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'QueueItem(id: $id, type: $type, retries: $retryCount)';
  }
}