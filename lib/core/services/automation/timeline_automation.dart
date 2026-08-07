import '../../../models/timeline_model.dart';
import '../../../repositories/interfaces/i_timeline_repository.dart';

class TimelineAutomation {
  final ITimelineRepository _timelineRepo;

  TimelineAutomation(this._timelineRepo);

  Future<void> logEvent({
    required String title,
    required String description,
    required String category, // Customer, Order, Payment, Expense, Delivery, Employee, System
    String recordId = '',
    String performedBy = 'Admin',
    Map<String, dynamic> metadata = const {},
  }) async {
    final event = TimelineModel(
      id: '',
      title: title,
      description: description,
      category: category,
      recordId: recordId,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      metadata: metadata,
    );
    await _timelineRepo.addTimelineEvent(event);
  }

  Future<List<TimelineModel>> getTimeline({String? category, String? recordId}) {
    return _timelineRepo.getTimelineEvents(category: category, recordId: recordId);
  }
}
