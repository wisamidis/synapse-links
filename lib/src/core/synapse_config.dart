/// Defines the conditions under which synchronization should occur.
enum SynapseSyncPolicy {
  /// Sync immediately whenever data changes (Default).
  immediate,

  /// Sync only when the device is connected to WiFi.
  wifiOnly,

  /// Sync only when the device is plugged in and charging.
  chargingOnly,

  /// Sync only when connected to WiFi AND charging.
  wifiAndCharging,
}

/// Configuration class for the Synapse library.
class SynapseConfig {
  /// The active synchronization policy.
  final SynapseSyncPolicy syncPolicy;

  /// The interval between periodic background sync attempts.
  final Duration syncInterval;

  /// Time-To-Live for local cache. 
  /// Data older than this will be considered expired.
  /// If null, data never expires.
  final Duration? cacheTtl;

  /// Whether to automatically delete expired data on startup.
  final bool clearExpiredCache;

  /// NEW: Feature 17 - Transparent Data Compression.
  /// If true, the storage driver should compress data before writing 
  /// and decompress upon reading (Gzip/Brotli).
  final bool enableDataCompression;

  /// NEW: Feature 16 - In-Memory Testing Mode.
  /// If true, the library should utilize volatile RAM storage 
  /// instead of persistent disk storage (useful for Unit Tests/CI).
  final bool memoryMode;

  /// Creates a new configuration instance.
  const SynapseConfig({
    this.syncPolicy = SynapseSyncPolicy.immediate,
    this.syncInterval = const Duration(minutes: 15),
    this.cacheTtl, 
    this.clearExpiredCache = false,
    this.enableDataCompression = false,
    this.memoryMode = false,
  });
}