import 'dart:async';
import '../logger/app_logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isOnline = true;
  final _controller = StreamController<bool>.broadcast();

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void updateStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(online);
      AppLogger.info('Network state changed: ${online ? "ONLINE 🌐" : "OFFLINE 🔌"}', 'NETWORK');
    }
  }

  void dispose() {
    _controller.close();
  }
}
