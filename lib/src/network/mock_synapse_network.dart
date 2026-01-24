import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_network.dart';
import 'synapse_response.dart';

/// A fake network implementation for testing and offline development.
/// Simulates latency and server-side logic.
class MockSynapseNetwork<T extends SynapseEntity> implements SynapseNetwork<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final Duration delay;
  final bool simulateErrors;

  // Static storage to simulate persistence during hot-restart
  static final Map<String, Map<String, dynamic>> _serverDb = {};

  const MockSynapseNetwork({
    required this.fromJson,
    this.delay = const Duration(milliseconds: 800),
    this.simulateErrors = false,
  });

  Future<void> _simulateNetwork() async {
    await Future.delayed(delay);
    if (simulateErrors) {
      // ✅ FIXED: Using positional parameters (Message, StatusCode)
      throw const NetworkException('Simulation: Network Failure', 500);
    }
  }

  @override
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams}) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Fetching all items...');
    return _serverDb.values.map((json) => fromJson(json)).toList();
  }

  @override
  Future<T> fetchOne(String id) async {
    await _simulateNetwork();
    if (_serverDb.containsKey(id)) return fromJson(_serverDb[id]!);
    // ✅ FIXED: Positional parameters
    throw const NetworkException('Item not found', 404);
  }

  @override
  Future<SynapseResponse> create(Map<String, dynamic> data) async {
    await _simulateNetwork();
    final mockData = Map<String, dynamic>.from(data);
    
    if (!mockData.containsKey('id')) mockData['id'] = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    if (!mockData.containsKey('updatedAt')) mockData['updatedAt'] = DateTime.now().toIso8601String();
    
    _serverDb[mockData['id']] = mockData;
    debugPrint("📡 Mock: Created item ${mockData['id']}");

    return SynapseResponse(isSuccess: true, statusCode: 201, data: fromJson(mockData));
  }

  @override
  Future<SynapseResponse> update(String id, Map<String, dynamic> changes) async {
    await _simulateNetwork();
    if (!_serverDb.containsKey(id)) {
        // ✅ FIXED: Positional parameters
        throw const NetworkException('Item not found', 404);
    }
    
    final mergedData = {..._serverDb[id]!, ...changes, 'updatedAt': DateTime.now().toIso8601String()};
    _serverDb[id] = mergedData;
    debugPrint("📡 Mock: Updated item $id");

    return SynapseResponse(isSuccess: true, statusCode: 200, data: fromJson(mergedData));
  }

  @override
  Future<SynapseResponse> delete(String id) async {
    await _simulateNetwork();
    if (!_serverDb.containsKey(id)) {
        // ✅ FIXED: Positional parameters
        throw const NetworkException('Item not found', 404);
    }
    
    _serverDb.remove(id);
    debugPrint("📡 Mock: Deleted item $id");
    return const SynapseResponse(isSuccess: true, statusCode: 200);
  }

  @override
  Future<SynapseResponse> uploadFile(String filePath) async {
    await _simulateNetwork();
    return const SynapseResponse(isSuccess: true, statusCode: 200, data: "https://mock.url/file.png");
  }

  @override
  Future<SynapseResponse> batchCreate(List<Map<String, dynamic>> dataList) async {
    await _simulateNetwork();
    debugPrint("📡 Mock: Batch Creating ${dataList.length} items...");
    
    for (var data in dataList) {
       final mockData = Map<String, dynamic>.from(data);
       if (!mockData.containsKey('id')) mockData['id'] = 'batch_${DateTime.now().millisecondsSinceEpoch}_${data.hashCode}';
       _serverDb[mockData['id']] = mockData;
    }
    return const SynapseResponse(isSuccess: true, statusCode: 201);
  }

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