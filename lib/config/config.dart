import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tuitu/utils/common_methods.dart';

class Config {
  static const String configFileName = 'config.json';
  static const String characterPresetsFileName = 'characterPresets.json';

  static Future<File> _getLocalFile({int type = 1}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File(type == 1
          ? '${directory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}$configFileName'
          : '${directory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}$characterPresetsFileName');
    } catch (e) {
      commonPrint('获取配置失败，请尝试重启软件');
    }
    return File('');
  }

  static Future<void> saveSettings(Map<String, dynamic> settings,
      {int type = 1}) async {
    final file = await _getLocalFile(type: type);
    Map<String, dynamic> existingSettings = await loadSettings(type: type);
    existingSettings.addAll(settings);
    await file.writeAsString(jsonEncode(existingSettings));
  }

  static Future<Map<String, dynamic>> loadSettings({int type = 1}) async {
    try {
      final file = await _getLocalFile(type: type);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      commonPrint(type == 1 ? '加载设置失败$e' : '加载人物预设失败$e');
      return {};
    }
    return {};
  }
}
