import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_network.dart';
import 'synapse_response.dart';

/// A robust Mock Network implementation for testing, offline development, and prototyping.
/// 
/// This class simulates a real REST API server behavior including:
/// - Artificial Network Latency (Delay).
/// - Random Error Simulation (e.g., 500 Internal Server Error).
/// - In-Memory Persistence (Static Storage) to keep data alive during hot-restarts.
/// - Batch Operations simulation.
/// 
/// Usage:
/// Pass this to [Synapse.create] or [SynapseRepositoryImpl] when you don't have a real backend yet.
class MockSynapseNetwork<T extends SynapseEntity> implements SynapseNetwork<T> {
  
  /// Factory function to convert a JSON Map into a concrete Entity [T].
  /// Required to return typed objects from the mock server.
  final T Function(Map<String, dynamic>) fromJson;

  /// The simulated network latency duration.
  /// Default is 800ms to mimic a slow 3G/4G connection.
  final Duration delay;

  /// If set to true, the mock network will randomly throw exceptions
  /// to test your app's error handling capabilities.
  final bool simulateErrors;

  /// Static storage acts as a "Server Database". 
  /// It is static so data persists across screen navigation and hot-restarts 
  /// as long as the app process is alive.
  static final Map<String, Map<String, dynamic>> _serverDb = {};

  /// Creates a new instance of [MockSynapseNetwork].
  /// 
  /// [fromJson] : The factory method for your entity (e.g., `User.fromJson`).
  /// [delay] : How long to wait before returning a response (default: 800ms).
  /// [simulateErrors] : Set to true to trigger fake network failures.
  const MockSynapseNetwork({
    required this.fromJson,
    this.delay = const Duration(milliseconds: 800),
    this.simulateErrors = false,
  });

  /// Simulates the network delay and potentially throws an error.
  /// This is called internally before every operation.
  Future<void> _simulateNetwork() async {
    await Future.delayed(delay);
    if (simulateErrors) {
      // Throwing a generic 500 Server Error for testing purposes.
      throw const NetworkException('Simulation: Network Failure', 500);
    }
  }

  /// Simulates fetching all records from the server.
  /// 
  /// Returns a list of entities [T] currently stored in the static memory.
  @override
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams}) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Fetching all items...');
    return _serverDb.values.map((json) => fromJson(json)).toList();
  }

  /// Simulates fetching a single record by its [id].
  /// 
  /// Throws [NetworkException] with 404 status if the item does not exist.
  @override
  Future<T> fetchOne(String id) async {
    await _simulateNetwork();
    if (_serverDb.containsKey(id)) {
      return fromJson(_serverDb[id]!);
    }
    throw const NetworkException('Item not found', 404);
  }

  /// Simulates creating a new record on the server.
  /// 
  /// - Assigns a mock 'id' if not present.
  /// - Assigns 'updatedAt' timestamp.
  /// - Stores the data in the static memory.
  /// 
  /// Returns a [SynapseResponse] containing the created entity.
  @override
  Future<SynapseResponse> create(Map<String, dynamic> data) async {
    await _simulateNetwork();
    final mockData = Map<String, dynamic>.from(data);
    
    // Generate a mock ID if the client didn't provide one
    if (!mockData.containsKey('id')) {
      mockData['id'] = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Set timestamp
    if (!mockData.containsKey('updatedAt')) {
      mockData['updatedAt'] = DateTime.now().toIso8601String();
    }
    
    _serverDb[mockData['id']] = mockData;
    debugPrint("📡 Mock: Created item ${mockData['id']}");

    return SynapseResponse(
      isSuccess: true, 
      statusCode: 201, 
      data: fromJson(mockData),
    );
  }

  /// Simulates updating an existing record.
  /// 
  /// Throws 404 if the ID doesn't exist.
  /// Merges the new [changes] with existing data.
  @override
  Future<SynapseResponse> update(String id, Map<String, dynamic> changes) async {
    await _simulateNetwork();
    
    if (!_serverDb.containsKey(id)) {
        throw const NetworkException('Item not found', 404);
    }
    
    // Merge existing data with changes and update timestamp
    final mergedData = {
      ..._serverDb[id]!, 
      ...changes, 
      'updatedAt': DateTime.now().toIso8601String()
    };
    
    _serverDb[id] = mergedData;
    debugPrint("📡 Mock: Updated item $id");

    return SynapseResponse(
      isSuccess: true, 
      statusCode: 200, 
      data: fromJson(mergedData),
    );
  }

  /// Simulates deleting a record.
  /// 
  /// Throws 404 if the item is not found.
  @override
  Future<SynapseResponse> delete(String id) async {
    await _simulateNetwork();
    
    if (!_serverDb.containsKey(id)) {
        throw const NetworkException('Item not found', 404);
    }
    
    _serverDb.remove(id);
    debugPrint("📡 Mock: Deleted item $id");
    
    return const SynapseResponse(isSuccess: true, statusCode: 200);
  }

  /// Simulates a file upload operation.
  /// 
  /// Returns a fake URL string.
  @override
  Future<SynapseResponse> uploadFile(String filePath) async {
    await _simulateNetwork();
    debugPrint("📡 Mock: File uploaded successfully ($filePath)");
    return const SynapseResponse(
      isSuccess: true, 
      statusCode: 200, 
      data: "https://mock.url/file.png",
    );
  }

  /// Simulates batch creation of multiple records.
  /// 
  /// Useful for testing bulk sync operations.
  @override
  Future<SynapseResponse> batchCreate(List<Map<String, dynamic>> dataList) async {
    await _simulateNetwork();
    debugPrint("📡 Mock: Batch Creating ${dataList.length} items...");
    
    for (var data in dataList) {
       final mockData = Map<String, dynamic>.from(data);
       if (!mockData.containsKey('id')) {
         mockData['id'] = 'batch_${DateTime.now().millisecondsSinceEpoch}_${data.hashCode}';
       }
       _serverDb[mockData['id']] = mockData;
    }
    
    return const SynapseResponse(isSuccess: true, statusCode: 201);
  }

  /// Simulates batch update of multiple records.
  @override
  Future<SynapseResponse> batchUpdate(List<Map<String, dynamic>> dataList) async {
    await _simulateNetwork();
    debugPrint("📡 Mock: Batch Updating ${dataList.length} items...");
    
    for (var data in dataList) {
      if (data.containsKey('id') && _serverDb.containsKey(data['id'])) {
         _serverDb[data['id']] = {..._serverDb[data['id']]!, ...data};
      }
    }
    
    return const SynapseResponse(isSuccess: true, statusCode: 200);
  }
}