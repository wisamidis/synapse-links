enum SynapseSyncPolicy {
  immediate,       // Sync ASAP (Data/WiFi)
  wifiOnly,        // Save data
  wifiAndCharging, // Background heavy tasks
  manual,          // Developer calls sync() explicitly
}

class SynapseConfig {
  final SynapseSyncPolicy syncPolicy;
  final Duration cacheTtl;
  final bool clearExpiredCache;
  final int maxRetries; // Added: For robustness

  const SynapseConfig({
    this.syncPolicy = SynapseSyncPolicy.immediate, // Changed: More UX friendly default
    this.cacheTtl = const Duration(days: 7), // Changed: 24h is too short for offline-first apps
    this.clearExpiredCache = false,
    this.maxRetries = 3,
  });
}