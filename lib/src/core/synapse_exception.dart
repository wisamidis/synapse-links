/// Base exception for SynapseLink errors.
class SynapseException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const SynapseException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'SynapseException: $message ${error ?? ""}';
}

/// Thrown when a network operation fails.
class NetworkException extends SynapseException {
  final int statusCode;

  // ✅ FIX: Used super parameters (super.message, super.error)
  const NetworkException(super.message, this.statusCode, [super.error, super.stackTrace]);

  @override
  String toString() => 'NetworkException [$statusCode]: $message';
}

/// Thrown when a local storage operation fails.
class StorageException extends SynapseException {
  // ✅ FIX: Used super parameters
  const StorageException(super.message, [super.error, super.stackTrace]);
}