import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, sync, audit }

class AppLogger {
  static void debug(String message, [String tag = 'DEBUG']) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String tag = 'INFO']) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String tag = 'WARN']) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace, String tag = 'ERROR']) {
    _log(LogLevel.error, '$message | Error: $error', tag);
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stacktrace: $stackTrace');
    }
  }

  static void sync(String message, [String tag = 'SYNC']) {
    _log(LogLevel.sync, message, tag);
  }

  static void audit(String message, [String tag = 'AUDIT']) {
    _log(LogLevel.audit, message, tag);
  }

  static void _log(LogLevel level, String message, String tag) {
    if (!kDebugMode) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final emoji = _getEmoji(level);
    debugPrint('$emoji [$timestamp] [$tag] $message');
  }

  static String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.sync:
        return '🔄';
      case LogLevel.audit:
        return '🔒';
    }
  }
}
