import 'sync_queue_manager.dart';

class SyncService {
  final SyncQueueManager _queueManager = SyncQueueManager();

  Future<void> syncAllPending() async {
    await _queueManager.processQueue();
  }
}
