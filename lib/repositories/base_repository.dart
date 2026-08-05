import 'package:flutter/foundation.dart';
import '../core/services/sync_queue_manager.dart';

abstract class BaseRepository {
  final SyncQueueManager queueManager = SyncQueueManager();

  @protected
  Future<void> enqueueSync({
    required String collection,
    required String docId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    await queueManager.enqueue(
      collection: collection,
      docId: docId,
      action: action,
      data: data,
    );
  }
}
