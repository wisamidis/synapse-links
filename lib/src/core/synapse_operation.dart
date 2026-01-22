enum SynapseOperationType {
  create,
  update,
  delete,
  upload,
}

enum SynapseSyncStatus {
  idle,           // Nothing to do
  syncing,        // Actively working
  upToDate,       // Added: Sync finished successfully
  offline,        // No network connection
  error,          // Something went wrong
}