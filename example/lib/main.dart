import 'package:flutter/material.dart';
import 'src/feature_showcase.dart';
import 'src/drift_integration.dart';
import 'src/isar_integration.dart';

void main() {
  runApp(const SynapseExampleApp());
}

class SynapseExampleApp extends StatelessWidget {
  const SynapseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse Link Examples',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const ExampleDashboard(),
    );
  }
}

class ExampleDashboard extends StatelessWidget {
  const ExampleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synapse Link V2 Demos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNavCard(
            context,
            title: 'Full Feature Showcase (ToDo App)',
            subtitle: 'Demonstrates Validation, Compression, Reactive UI & Conflict Resolution.',
            icon: Icons.check_circle_outline,
            target: const FeatureShowcase(),
          ),
          const SizedBox(height: 10),
          _buildNavCard(
            context,
            title: 'Drift (SQL) Integration',
            subtitle: 'How to use Synapse with Drift/SQLite backend.',
            icon: Icons.table_chart,
            target: const DriftIntegrationDemo(),
          ),
          const SizedBox(height: 10),
          _buildNavCard(
            context,
            title: 'Isar (NoSQL) Integration',
            subtitle: 'High-performance storage using Isar.',
            icon: Icons.bolt,
            target: const IsarIntegrationDemo(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget target,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      ),
    );
  }
}