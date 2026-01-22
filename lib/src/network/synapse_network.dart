import '../core/synapse_entity.dart';

/// Abstract contract for network operations.
/// 
/// Implementations can be Dio, Http, GraphQL, or Mock.
abstract class SynapseNetwork<T extends SynapseEntity> {
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams});

  Future<T> fetchOne(String id);

  Future<T> create(Map<String, dynamic> data);

  Future<T> update(String id, Map<String, dynamic> data);

  Future<void> delete(String id);

  Future<String> uploadFile(String filePath);
}