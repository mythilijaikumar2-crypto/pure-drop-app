import '../logger/app_logger.dart';

/// Pure Local Mock NotificationService.
class NotificationService {
  Future<void> initialize() async {
    AppLogger.info('Local Mock NotificationService initialized', 'NOTIFICATIONS');
  }

  void sendMockNotification(String title, String body) {
    AppLogger.info('Local notification: $title - $body', 'NOTIFICATIONS');
  }
}
