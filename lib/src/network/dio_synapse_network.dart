import 'package:dio/dio.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_network.dart';

/// Implementation of SynapseNetwork using the Dio package.
/// Supports RESTful APIs.
class DioSynapseNetwork<T extends SynapseEntity> implements SynapseNetwork<T> {
  final Dio dio;
  final String baseUrl;
  final T Function(Map<String, dynamic>) fromJson;

  DioSynapseNetwork({
    required this.dio,
    required this.baseUrl,
    required this.fromJson,
  });

  @override
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(baseUrl, queryParameters: queryParams);
      
      // Handle different API wrapper styles
      // Style A: [ {..}, {..} ]
      // Style B: { "data": [ {..}, {..} ], "meta": {..} }
      final rawData = (response.data is List) 
          ? response.data 
          : (response.data['data'] ?? []);

      if (rawData is! List) {
        throw const NetworkException('Invalid API response format: Expected List');
      }
          
      return rawData.map((e) {
        if (e is Map<String, dynamic>) {
          return fromJson(e);
        }
        // Fallback for unsafe parsing
        return fromJson(Map<String, dynamic>.from(e));
      }).toList();

    } on DioException catch (e) {
      throw NetworkException(
        'FetchAll failed: ${e.message}', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    } catch (e) {
       throw NetworkException('Unexpected error during fetchAll', originalError: e);
    }
  }

  @override
  Future<T> fetchOne(String id) async {
    try {
      final response = await dio.get('$baseUrl/$id');
      return fromJson(response.data);
    } on DioException catch (e) {
      throw NetworkException(
        'FetchOne failed for ID: $id', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    }
  }

  @override
  Future<T> create(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(baseUrl, data: data);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw NetworkException(
        'Create failed', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    }
  }

  @override
  Future<T> update(String id, Map<String, dynamic> data) async {
    try {
      // CHANGED: Use PATCH instead of PUT.
      // PUT replaces the entire resource. PATCH updates only provided fields.
      // Since we are sending 'deltas', PATCH is mandatory to prevent data loss.
      final response = await dio.patch('$baseUrl/$id', data: data);
      
      return fromJson(response.data);
    } on DioException catch (e) {
      throw NetworkException(
        'Update failed for ID: $id', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await dio.delete('$baseUrl/$id');
    } on DioException catch (e) {
      throw NetworkException(
        'Delete failed for ID: $id', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    }
  }

  @override
  Future<String> uploadFile(String path) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });
      
      // Standardize upload endpoint to /upload or allow configuration
      final response = await dio.post('$baseUrl/upload', data: formData);
      
      // Adapt to common server responses for file uploads
      if (response.data is Map) {
        return response.data['url'] ?? response.data['path'] ?? response.data['file_url'] ?? '';
      } else if (response.data is String) {
        return response.data;
      }
      return '';
      
    } on DioException catch (e) {
      throw NetworkException(
        'Upload failed', 
        statusCode: e.response?.statusCode, 
        originalError: e
      );
    }
  }
}