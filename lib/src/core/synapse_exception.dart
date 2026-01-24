/// Base exception class for the library.
class SynapseException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const SynapseException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'SynapseException: $message ${error != null ? '\n$error' : ''}';
}

/// Thrown when local storage operations fail.
class StorageException extends SynapseException {
  const StorageException(String message, [dynamic error, StackTrace? stackTrace]) 
      : super(message, error, stackTrace);
}

/// Thrown when network operations fail.
class NetworkException extends SynapseException {
  final int? statusCode;
  
  // FIXED: Defined 'error' as a named parameter inside {} to allow "error: e" calls.
  const NetworkException(String message, {this.statusCode, dynamic error, StackTrace? stackTrace})
      : super(message, error, stackTrace);
}