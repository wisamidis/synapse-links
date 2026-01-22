class SynapseException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const SynapseException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() {
    if (originalError != null) return 'SynapseException: $message | Inner: $originalError';
    return 'SynapseException: $message';
  }
}

class NetworkException extends SynapseException {
  final int? statusCode;

  const NetworkException(String message, {this.statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, originalError, stackTrace);

  @override
  String toString() => 'NetworkException [${statusCode ?? 'Unknown'}]: $message';
}

class StorageException extends SynapseException {
  const StorageException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, originalError, stackTrace);
}

// Added: New specific exception for Sync Conflicts
class SyncConflictException extends SynapseException {
  SyncConflictException(String id) : super('Conflict detected for entity ID: $id');
}