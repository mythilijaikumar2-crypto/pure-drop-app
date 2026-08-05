import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/hive_service.dart';
import 'firebase_service.dart';

class SyncQueueItem {
  final String id;
  final String collection;
  final String docId;
  final String action; // 'set' or 'delete'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncQueueItem({
    required this.id,
    required this.collection,
    required this.docId,
    required this.action,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'docId': docId,
        'action': action,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] ?? '',
        collection: json['collection'] ?? '',
        docId: json['docId'] ?? '',
        action: json['action'] ?? 'set',
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      );
}

class SyncQueueManager {
  static final SyncQueueManager _instance = SyncQueueManager._internal();
  factory SyncQueueManager() => _instance;
  SyncQueueManager._internal();

  static const String queueBoxName = 'sync_queue_box';
  final FirebaseService _firebase = FirebaseService();
  bool _isProcessing = false;

  // Add a pending mutation to local sync queue
  Future<void> enqueue({
    required String collection,
    required String docId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    try {
      final queueItem = SyncQueueItem(
        id: '$collection-$docId-${DateTime.now().millisecondsSinceEpoch}',
        collection: collection,
        docId: docId,
        action: action,
        data: data,
        timestamp: DateTime.now(),
      );

      await HiveService.saveData(queueBoxName, queueItem.id, jsonEncode(queueItem.toJson()));
      if (kDebugMode) {
        debugPrint('📥 Enqueued offline sync task: ${queueItem.collection}/${queueItem.docId} (${queueItem.action})');
      }

      // Trigger queue processing in background
      processQueue();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error enqueuing sync item: $e');
      }
    }
  }

  // Process all queued sync items with Firebase Firestore
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final rawItems = HiveService.getAll(queueBoxName);
      if (rawItems.isEmpty) {
        _isProcessing = false;
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Processing ${rawItems.length} offline sync items...');
      }

      for (final raw in rawItems) {
        try {
          final jsonMap = jsonDecode(raw as String);
          final item = SyncQueueItem.fromJson(jsonMap);

          if (item.action == 'delete') {
            await _firebase.deleteDocument(
              collection: item.collection,
              docId: item.docId,
            );
          } else {
            await _firebase.syncDocument(
              collection: item.collection,
              docId: item.docId,
              data: item.data,
            );
          }

          // Remove item from queue after successful push
          await HiveService.deleteData(queueBoxName, item.id);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Sync queue item failed, keeping in queue: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error in processQueue: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }
}
