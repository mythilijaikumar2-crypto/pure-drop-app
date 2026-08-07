import '../../models/timeline_model.dart';

abstract class ITimelineRepository {
  Future<List<TimelineModel>> getTimelineEvents({String? category, String? recordId});
  Future<bool> addTimelineEvent(TimelineModel event);
  Future<bool> clearTimeline();
}
