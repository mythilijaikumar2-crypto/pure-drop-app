import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/hive_service.dart';

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
        debugPrint('📥 Enqueued local sync task: ${queueItem.collection}/${queueItem.docId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error enqueuing sync item: $e');
      }
    }
  }

  Future<void> processQueue() async {
    // Pure local mode — queue operations remain safely stored in Hive
  }
}
