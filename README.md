# SynapseLink 🚀

[![Pub Version](https://img.shields.io/pub/v/synapse_link)](https://pub.dev/packages/synapse_link)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**SynapseLink** is a high-performance, offline-first data synchronization library for Flutter. It seamlessly bridges the gap between local persistence and remote servers using an advanced architecture that supports Optimistic UI, Delta Synchronization, and automatic Conflict Resolution.

---

## ✨ Key Features

* **Offline-First Architecture**: Your application remains fully functional without an internet connection, treating local storage as the primary source of truth.
* **Optimistic UI Updates**: Provide instant feedback to users by updating the UI immediately while synchronization happens in the background.
* **Delta Sync Engine**: Minimize bandwidth and battery usage by transmitting only the fields that have actually changed.
* **Conflict Resolution**: Built-in strategies like **Smart Merge** and **Last-Write-Wins** to handle data discrepancies between devices and servers.
* **Background Synchronization**: Robust integration with Workmanager ensures data is synced even when the app is closed or in the background.
* **Developer Suite**: Includes ready-to-use widgets like `SynapseSyncIndicator` and a comprehensive `SynapseDashboard` for real-time monitoring.

---

## 🚀 Getting Started

### Installation

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  synapse_link: ^1.0.0
```

### Basic Usage

1. **Initialize the Provider**: Wrap your application with `SynapseProvider` to inject the repository logic.

```dart
SynapseProvider<Task>(
  storage: HiveStorage<Task>(boxName: 'tasks', fromJson: Task.fromJson),
  network: DioSynapseNetwork(baseUrl: '[https://api.example.com/tasks](https://api.example.com/tasks)', fromJson: Task.fromJson),
  child: MyApp(),
);
```

2. **Reactive UI**: Use `SynapseBuilder` to automatically rebuild your UI whenever local data or sync status changes.

```dart
SynapseBuilder<Task>(
  builder: (context, tasks, status) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskTile(tasks[index]),
    );
  },
);
```

---

## 🛠 Developer Dashboard

SynapseLink includes a built-in debugging dashboard that allows you to inspect the sync queue, monitor pending tasks, and manage the local cache directly from your app.

```dart
// Open the dashboard from any button or menu
Navigator.push(
  context, 
  MaterialPageRoute(builder: (_) => const SynapseDashboard<Task>()),
);
```

---

## 🤝 Community & Support

We are committed to making **SynapseLink** the most reliable synchronization tool for the Flutter community. Your feedback and contributions are highly valued.

> **Get in Touch:**
> If you encounter any bugs or would like to request a new feature for this library, please feel free to reach out. I am dedicated to improving SynapseLink based on your needs!
> 
> 👾 **Discord Username:** `Vortex Shadow`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.