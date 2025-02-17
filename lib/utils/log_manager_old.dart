import 'package:logger/logger.dart';

class LogManagerOld {
  static final LogManagerOld _instance = LogManagerOld._internal();
  late final Logger _logger;

  factory LogManagerOld() {
    return _instance;
  }

  LogManagerOld._internal() {
    _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 3,
          // number of method calls to be displayed
          errorMethodCount: 8,
          // number of method calls if stacktrace is provided
          lineLength: 120,
          // width of the output
          colors: true,
          // Colorful log messages
          printEmojis: true,
          // Print an emoji for each log message
          dateTimeFormat: DateTimeFormat.dateAndTime, // Should each log have a timestamp
        )
    );
  }

  void logInfo(dynamic message) {
    _logger.i(message);
  }

  void logWarning(dynamic message) {
    _logger.w(message);
  }

  void logError(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void logDebug(dynamic message) {
    _logger.d(message);
  }

  //打印所有类型的日志包含map和list等等
  void logAny(dynamic message) {
    _logger.i(message);
  }
}