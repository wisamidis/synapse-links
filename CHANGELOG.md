## [1.0.4] - 2026-01-26

### 🚀 Major Release: Architecture Overhaul & Developer Experience

This release introduces a completely redesigned architecture focusing on ease of use, performance, and flexibility.

### ✨ New Features

* **Facade Initialization:** Introduced `Synapse.create(...)` for a streamlined, one-line setup experience. Reduced boilerplate code by 80%.
* **Multi-Driver Storage Support:**
    * Added **Drift (SQL)** support via `DriftStorage`.
    * Added **Isar (NoSQL)** support via `IsarStorage`.
    * Enhanced **Hive** support with transparent compression.
* **Pre-Sync Validation Hooks:** New `validator` parameter allows developers to define rules that run before data enters the local database or sync queue, preventing garbage data.
* **Transparent Data Compression:** Added `enableDataCompression` to `SynapseConfig`. Automatically compresses data (Gzip) before storage to save space on large datasets.
* **In-Memory Testing Mode:** Added `memoryMode` to run the entire library in RAM, enabling lightning-fast unit tests without disk I/O.
* **Conflict Resolution UI:** Introduced `SynapseConflictResolver`, a pre-built Widget to handle data conflicts visually with the user.
* **Reactive Adapters:** Added `SynapseReactiveBuilder` and `SynapseProvider` for seamless integration with Flutter's widget tree (Riverpod/Bloc ready).

### 🛠 Improvements

* Refactored `SynapseRepository` to use the Strategy Pattern for storage drivers.
* Optimized `QueueStorage` for batch processing.
* Improved error handling for offline scenarios.
* Cleaned up library exports for a better IntelliSense experience.

### ⚠️ Breaking Changes

* Direct instantiation of `SynapseRepositoryImpl` is now discouraged in favor of `Synapse.create`.
* `HiveStorage` now requires a `fromJson` factory in its constructor.