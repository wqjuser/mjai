import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LogManager {
  static final LogManager _instance = LogManager._internal();
  late Logger _logger;
  late String _logDirectory;
  late File _currentLogFile;
  bool _isInitialized = false;

  // Singleton pattern
  factory LogManager() {
    return _instance;
  }

  // Getter that ensures logger is initialized
  Logger get logger {
    if (!_isInitialized) {
      throw StateError('LogManager not initialized. Call initialize() first.');
    }
    return _logger;
  }

  LogManager._internal();

  // Initialize the logger
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get the log directory
    _logDirectory = await _getLogDirectory();

    // Create current log file with date
    _currentLogFile = await _createLogFile();

    // Create multi output for both console and file
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 6,
        errorMethodCount: 8,
        lineLength: 120,
        colors: false,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
      output: MultiOutput([
        ConsoleOutput(), // Print to console
        if (!kDebugMode) FileOutput(file: _currentLogFile), // Print to file
      ]),
    );

    _isInitialized = true;
  }

  Future<String> _getLogDirectory() async {
    late String basePath;

    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'];
      if (appData == null) {
        throw Exception('Cannot find LOCALAPPDATA environment variable');
      }
      basePath = path.join(appData, 'MoJingAI', 'logs');
    } else if (Platform.isMacOS) {
      final supportDir = await getApplicationSupportDirectory();
      basePath = path.join(supportDir.path, 'MoJingAI', 'logs');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Create directory if it doesn't exist
    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return basePath;
  }

  Future<File> _createLogFile() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final fileName = 'log_${formatter.format(now)}.txt';
    final logFilePath = path.join(_logDirectory, fileName);

    return File(logFilePath);
  }
}
