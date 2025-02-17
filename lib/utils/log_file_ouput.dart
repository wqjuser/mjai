import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class FileLogOutput extends LogOutput {
  final Future<File> _fileFuture;

  FileLogOutput() : _fileFuture = _initFile();

  static Future<File> _initFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs.txt');
    if (!await file.exists()) {
      await file.create();
    }
    return file;
  }

  @override
  void output(OutputEvent event) async {
    final File file = await _fileFuture;
    final String log = event.lines.join('\n');
    file.writeAsStringSync('$log\n', mode: FileMode.append);
  }
}
