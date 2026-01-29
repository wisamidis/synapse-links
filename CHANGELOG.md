## [1.0.5] - 2026-01-29

### 🛡️ The Enterprise Reliability Update: Security, Background Sync & Stability

This release transforms SynapseLink from a sync engine into a full lifecycle management system. We focused on "Day 2" operations: debugging, security compliance, background persistence, and UI performance.

### ✨ New Features

* **🔍 Sync Audit Trail (Built-in Logging):**
    * Introduced `SynapseLogRegistry`. The library now maintains a detailed internal history of every sync attempt, success, and failure.
    * Added `Synapse.logs` and `Synapse.logStream` to allow developers to display logs in-app or send them to crash reporting tools (Sentry/Crashlytics) easily.

* **🧹 One-Line Secure Wipe:**
    * Added `Synapse.wipeAndReset()`. A single command that securely destroys all local databases, clears the pending queue, cancels background tasks, and flushes logs. Perfect for "Logout" functionality ensuring no data leaks between users.

* **💓 Scheduled Background Heartbeat:**
    * Added `Synapse.schedulePeriodicSync()`. The library can now wake up the app in the background (every 15+ minutes) to fetch data even when the app is closed, powered by `workmanager`.

* **⚡ Smart Stream Throttling:**
    * Implemented intelligent debouncing in `watchAll()`. Even if thousands of updates arrive per second, the UI now receives a maximum of one update every 50ms, eliminating UI jank and keeping FPS high.

* **🤖 Auto-Type Conversion Engine:**
    * Added automatic serialization for complex types. `DateTime` and nested Maps are now automatically converted to JSON-safe primitives before storage and sync, removing the need for manual boilerplate conversion code.

### 🛠 Improvements

* **Dependency Update:** Added `rxdart`, `workmanager`, `connectivity_plus`, and `battery_plus` to core dependencies to support the new features.
* **Battery & Network Awareness:** Background sync now automatically pauses if the device is low on battery or offline.
* **Batch Processing Logic:** Enhanced the queue processing to handle rapid-fire create operations more efficiently.

### ⚠️ Migration Guide

* **New Permissions Required:** To use the new Background Heartbeat feature, you must add `WAKE_LOCK` permissions to your Android Manifest and enable `Background Fetch` in iOS capabilities.
* **Initialization:** Ensure `SynapseBackgroundService.initialize()` is called if you plan to use background syncing.