/// A standardized response object for network operations.
///
/// This class wraps the result of API calls, providing a consistent way
/// to handle success states, data, and error messages.
class SynapseResponse<T> {
  /// Indicates if the operation was successful (HTTP 2xx).
  final bool isSuccess;

  /// The HTTP status code returned by the server (e.g., 200, 201, 404).
  final int? statusCode;

  /// The parsed data returned from the server (optional).
  final T? data;

  /// A descriptive error message if the operation failed.
  final String? errorMessage;

  /// Creates a new [SynapseResponse].
  const SynapseResponse({
    required this.isSuccess,
    this.statusCode,
    this.data,
    this.errorMessage,
  });
}