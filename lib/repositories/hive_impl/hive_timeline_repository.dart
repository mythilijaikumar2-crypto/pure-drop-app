import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/timeline_model.dart';
import '../interfaces/i_timeline_repository.dart';

class HiveTimelineRepository implements ITimelineRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<TimelineModel>> getTimelineEvents({String? category, String? recordId}) async {
    try {
      final items = HiveService.getAll(AppConstants.timelineBoxName);
      final events = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return TimelineModel.fromJson(json);
      }).toList();

      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return events.where((e) {
        if (category != null && category.isNotEmpty && category != 'All') {
          if (e.category.toLowerCase() != category.toLowerCase()) return false;
        }
        if (recordId != null && recordId.isNotEmpty) {
          if (e.recordId != recordId) return false;
        }
        return true;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> addTimelineEvent(TimelineModel event) async {
    final box = HiveService.getBox(AppConstants.timelineBoxName);
    final id = event.id.isEmpty ? 'TL-${_uuid.v4().substring(0, 6).toUpperCase()}' : event.id;
    final newEvent = TimelineModel(
      id: id,
      title: event.title,
      description: event.description,
      category: event.category,
      recordId: event.recordId,
      timestamp: event.timestamp,
      performedBy: event.performedBy,
      metadata: event.metadata,
    );

    try {
      await box.put(id, jsonEncode(newEvent.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clearTimeline() async {
    final box = HiveService.getBox(AppConstants.timelineBoxName);
    try {
      await box.clear();
      return true;
    } catch (_) {
      return false;
    }
  }
}
