import 'package:flutter/material.dart';

/// Feature 20: Isar Integration Example
/// This file demonstrates how to setup the repository with a NoSQL Isar backend.
class IsarIntegrationDemo extends StatelessWidget {
  const IsarIntegrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isar (NoSQL) Strategy')),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to initialize with Isar:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '1. Open Isar instance.\n'
              '2. Use IsarStorage wrapper.\n'
              '3. Enjoy blazing fast read/write speeds.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Divider(),
            Text('Code Snippet:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Card(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '''
final isar = await Isar.open([UserSchema]);

final repository = SynapseRepositoryImpl<UserEntity>(
  storage: IsarStorage<UserEntity, UserIsarObject>(
    isar: isar,
    collection: isar.userIsarObjects,
    toIsar: (e) => UserIsarObject()..id = e.id.hashCode ..name = e.name,
    fromIsar: (i) => UserEntity(id: i.id.toString(), name: i.name),
  ),
  network: MyNetworkService(),
  queueStorage: QueueStorage(),
);
                  ''',
                  style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}