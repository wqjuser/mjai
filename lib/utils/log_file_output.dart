// Custom FileOutput implementation
import 'dart:io';

import 'package:logger/logger.dart';

// 自定义文件输出类，去除颜色代码
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  IOSink? _sink;

  // 匹配开头的 [38;5;12m 和结尾的 [0m\n
  static final _ansiEscapePattern = RegExp(r'\[38;5;12m|\[0m$');

  FileOutput({
    required this.file,
    this.overrideExisting = false,
  });

  @override
  Future<void> init() async {
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
    );
  }

  @override
  void output(OutputEvent event) {
    final cleanLines = event.lines
        .map((line) => line.replaceAll(_ansiEscapePattern, ''))
        .toList();
    _sink?.writeAll(cleanLines, '\n');
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}