import 'package:dio/dio.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_network.dart';
import 'synapse_response.dart';

/// Implementation of [SynapseNetwork] using the Dio HTTP client.
class DioSynapseNetwork<T extends SynapseEntity> implements SynapseNetwork<T> {
  final Dio dio;
  final String baseUrl;
  final T Function(Map<String, dynamic>) fromJson;

  DioSynapseNetwork({required this.dio, required this.baseUrl, required this.fromJson});

  @override
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(baseUrl, queryParameters: queryParams);
      final rawData = (response.data is List) ? response.data : (response.data['data'] ?? []);
      
      // ✅ FIXED: Positional params for NetworkException
      if (rawData is! List) throw const NetworkException('Invalid format', 500);
      return rawData.map((e) => fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      // ✅ FIXED: Positional params (Message, StatusCode, Error)
      throw NetworkException('FetchAll failed', e.response?.statusCode ?? 500, e);
    } catch (e) {
      throw NetworkException('Unexpected error', 500, e);
    }
  }

  @override
  Future<T> fetchOne(String id) async {
    try {
      final response = await dio.get('$baseUrl/$id');
      return fromJson(response.data);
    } on DioException catch (e) {
      throw NetworkException('FetchOne failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> create(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(baseUrl, data: data);
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode, data: response.data);
    } on DioException catch (e) {
      throw NetworkException('Create failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.patch('$baseUrl/$id', data: data);
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode, data: response.data);
    } on DioException catch (e) {
      throw NetworkException('Update failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> delete(String id) async {
    try {
      final response = await dio.delete('$baseUrl/$id');
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode);
    } on DioException catch (e) {
      throw NetworkException('Delete failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> uploadFile(String path) async {
    try {
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(path)});
      final response = await dio.post('$baseUrl/upload', data: formData);
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode, data: response.data);
    } on DioException catch (e) {
      throw NetworkException('Upload failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> batchCreate(List<Map<String, dynamic>> dataList) async {
    try {
      final response = await dio.post('$baseUrl/batch/create', data: {'items': dataList});
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode, data: response.data);
    } on DioException catch (e) {
      throw NetworkException('Batch Create failed', e.response?.statusCode ?? 500, e);
    }
  }

  @override
  Future<SynapseResponse> batchUpdate(List<Map<String, dynamic>> dataList) async {
    try {
      final response = await dio.post('$baseUrl/batch/update', data: {'items': dataList});
      return SynapseResponse(isSuccess: true, statusCode: response.statusCode, data: response.data);
    } on DioException catch (e) {
      throw NetworkException('Batch Update failed', e.response?.statusCode ?? 500, e);
    }
  }
}