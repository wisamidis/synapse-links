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

  /// ✅ Fixed: Time-To-Live for local cache. 
  /// Data older than this will be considered expired.
  /// If null, data never expires.
  final Duration? cacheTtl;

  /// ✅ Fixed: Whether to automatically delete expired data on startup.
  final bool clearExpiredCache;

  /// Creates a new configuration instance.
  const SynapseConfig({
    this.syncPolicy = SynapseSyncPolicy.immediate,
    this.syncInterval = const Duration(minutes: 15),
    this.cacheTtl, // Default is null (no expiry)
    this.clearExpiredCache = false,
  });
}