import 'package:flutter/material.dart';

class DriftIntegrationDemo extends StatelessWidget {
  const DriftIntegrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drift (SQL) Setup')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Initialization with Synapse 1.0.3:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.black87,
              child: const Text(
                '''
final repository = Synapse.create<UserEntity>(
  // Just swap HiveStorage with DriftStorage!
  storage: DriftStorage(
    database: myDriftDb,
    table: myDriftDb.users,
    toCompanion: (u) => UsersCompanion(...),
    fromData: (d) => UserEntity(...),
  ),
  network: DioSynapseNetwork(...),
  queue: QueueStorage(),
);
                ''',
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}