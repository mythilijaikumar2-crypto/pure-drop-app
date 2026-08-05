import 'package:firebase_messaging/firebase_messaging.dart';
import '../logger/app_logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('Notification permission granted', 'NOTIFICATIONS');
      }

      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token', 'NOTIFICATIONS');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Foreground notification received: ${message.notification?.title}', 'NOTIFICATIONS');
      });
    } catch (e) {
      AppLogger.error('Failed to initialize notifications', e, null, 'NOTIFICATIONS');
    }
  }
}
