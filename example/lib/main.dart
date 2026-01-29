import 'package:flutter/material.dart';
import 'src/feature_showcase.dart';
import 'src/drift_integration.dart';
import 'src/isar_integration.dart';
import 'src/new_features_demo.dart';

void main() {
  runApp(const SynapseExampleApp());
}

class SynapseExampleApp extends StatelessWidget {
  const SynapseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse Link Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ExampleDashboard(),
    );
  }
}

class ExampleDashboard extends StatelessWidget {
  const ExampleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synapse Link V1.1')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNavCard(
            context,
            title: 'New Features Lab',
            subtitle: 'Audit Logs, Wipe, Throttling & Background Sync',
            icon: Icons.science,
            target: const NewFeaturesDemo(),
          ),
          const SizedBox(height: 10),
          _buildNavCard(
            context,
            title: 'Full Feature Showcase',
            subtitle: 'ToDo App with Validation & Conflict Resolution',
            icon: Icons.check_circle_outline,
            target: const FeatureShowcase(),
          ),
          const SizedBox(height: 10),
          _buildNavCard(
            context,
            title: 'Drift (SQL) Integration',
            subtitle: 'Synapse + SQLite Backend',
            icon: Icons.table_chart,
            target: const DriftIntegrationDemo(),
          ),
          const SizedBox(height: 10),
          _buildNavCard(
            context,
            title: 'Isar (NoSQL) Integration',
            subtitle: 'Synapse + Isar Backend',
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
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      ),
    );
  }
}