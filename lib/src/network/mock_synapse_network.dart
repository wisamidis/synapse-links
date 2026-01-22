import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/synapse_entity.dart';
import '../core/synapse_exception.dart';
import 'synapse_network.dart';

/// A fake network implementation for testing and offline development.
class MockSynapseNetwork<T extends SynapseEntity> implements SynapseNetwork<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final Duration delay;
  final bool simulateErrors;

  // Static storage to simulate persistence during hot-restart
  static final Map<String, Map<String, dynamic>> _serverDb = {};

  const MockSynapseNetwork({
    required this.fromJson,
    this.delay = const Duration(milliseconds: 800), // More realistic delay
    this.simulateErrors = false,
  });

  Future<void> _simulateNetwork() async {
    await Future.delayed(delay);
    if (simulateErrors) {
      throw NetworkException('Simulation: Random Network Failure', statusCode: 500);
    }
  }

  @override
  Future<List<T>> fetchAll({Map<String, dynamic>? queryParams}) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Fetching all items (${_serverDb.length} found)...');
    
    // Simulate Pagination if needed based on queryParams
    return _serverDb.values.map((json) => fromJson(json)).toList();
  }

  @override
  Future<T> fetchOne(String id) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Fetching item: $id');
    
    if (_serverDb.containsKey(id)) {
      return fromJson(_serverDb[id]!);
    }
    
    // Simulate real 404 error instead of fake data
    throw NetworkException('Item not found', statusCode: 404);
  }

  @override
  Future<T> create(Map<String, dynamic> data) async {
    await _simulateNetwork();
    
    final mockData = Map<String, dynamic>.from(data);
    
    // Ensure ID exists
    if (!mockData.containsKey('id')) {
      mockData['id'] = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    }
    // Ensure timestamp
    if (!mockData.containsKey('updatedAt')) {
       mockData['updatedAt'] = DateTime.now().toIso8601String();
    }
    
    debugPrint("📡 Mock: Created item ${mockData['id']}");
    _serverDb[mockData['id']] = mockData;
    
    return fromJson(mockData);
  }

  @override
  Future<T> update(String id, Map<String, dynamic> changes) async {
    await _simulateNetwork();
    
    if (!_serverDb.containsKey(id)) {
       throw NetworkException('Item not found for update', statusCode: 404);
    }
    
    debugPrint('📡 Mock: PATCH item $id with: $changes');
    
    final oldData = _serverDb[id]!;
    
    // Merge changes (PATCH behavior)
    final mergedData = {
      ...oldData,
      ...changes,
      'updatedAt': DateTime.now().toIso8601String(), // Update timestamp
    };
    
    _serverDb[id] = mergedData;

    return fromJson(mergedData);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Deleted item $id');
    if (!_serverDb.containsKey(id)) {
       throw NetworkException('Item not found for delete', statusCode: 404);
    }
    _serverDb.remove(id);
  }

  @override
  Future<String> uploadFile(String filePath) async {
    await _simulateNetwork();
    debugPrint('📡 Mock: Uploaded file from $filePath');
    return "https://via.placeholder.com/150";
  }
}