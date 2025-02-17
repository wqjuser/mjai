// Usage example
import 'package:logger/logger.dart';

import 'log_manager.dart';

// Helper class for logging
class LoggerHelper {
  static LogManager? _logManager;
  static bool _initializing = false;
  static final List<_PendingLog> _pendingLogs = [];

  static Future<void> _ensureInitialized() async {
    if (_logManager != null) return;

    if (_initializing) {
      // Wait a bit and try again
      await Future.delayed(const Duration(milliseconds: 100));
      return _ensureInitialized();
    }

    _initializing = true;
    _logManager = LogManager();
    await _logManager!.initialize();
    _initializing = false;

    // Process any pending logs
    for (final log in _pendingLogs) {
      log.process(_logManager!.logger);
    }
    _pendingLogs.clear();
  }

  static Future<void> debug(dynamic message) async {
    await _log((logger) => logger.d(message));
  }

  static Future<void> info(dynamic message) async {
    await _log((logger) => logger.i(message));
  }

  static Future<void> warning(dynamic message) async {
    await _log((logger) => logger.w(message));
  }

  static Future<void> error(dynamic message, [dynamic error, StackTrace? stackTrace]) async {
    await _log((logger) => logger.e(message, error: error, stackTrace: stackTrace));
  }

  static Future<void> _log(void Function(Logger) logFunction) async {
    try {
      await _ensureInitialized();
      logFunction(_logManager!.logger);
    } catch (e) {
      // If initialization is still in progress, queue the log
      _pendingLogs.add(_PendingLog(logFunction));
    }
  }
}

// Helper class to store pending logs
class _PendingLog {
  final void Function(Logger) logFunction;

  _PendingLog(this.logFunction);

  void process(Logger logger) {
    logFunction(logger);
  }
}