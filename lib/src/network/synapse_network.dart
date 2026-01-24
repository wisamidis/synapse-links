import '../core/synapse_entity.dart';
import 'synapse_response.dart'; 

/// Abstract contract for network operations.
/// All implementations (Dio, Mock, etc.) must adhere to this contract.
abstract class SynapseNetwork<T extends SynapseEntity> {
  /// Fetches all items from the server.
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams});
  
  /// Fetches a single item by ID.
  Future<T> fetchOne(String id);
  
  /// Creates a single item.
  Future<SynapseResponse> create(Map<String, dynamic> data);
  
  /// Updates a single item.
  Future<SynapseResponse> update(String id, Map<String, dynamic> data);
  
  /// Deletes a single item.
  Future<SynapseResponse> delete(String id);
  
  /// Uploads a file.
  Future<SynapseResponse> uploadFile(String filePath);

  /// ✅ Feature 11: Batch Creation
  /// Sends a list of items to be created in a single request.
  Future<SynapseResponse> batchCreate(List<Map<String, dynamic>> dataList);

  /// ✅ Feature 11: Batch Update
  /// Sends a list of items to be updated in a single request.
  Future<SynapseResponse> batchUpdate(List<Map<String, dynamic>> dataList);
}