import 'package:flutter/services.dart';
import 'package:tuitu/services/screenshot_exception.dart';

import '../json_models/display.dart';

class ScreenshotManager {
  static const MethodChannel _channel = MethodChannel('screenshot_channel');

  // 获取所有显示器信息
  Future<List<Display>> getDisplays() async {
    try {
      final List<dynamic> displays = await _channel.invokeMethod('getDisplays');
      return displays.map((display) => Display.fromMap(display)).toList();
    } on PlatformException catch (e) {
      throw ScreenshotException('Failed to get displays: ${e.message}');
    }
  }

  // 捕获指定显示器的屏幕截图
  Future<String> captureDisplay(int displayId) async {
    try {
      final String? path = await _channel.invokeMethod('captureDisplay', {
        'displayId': displayId,
      });

      if (path == null) {
        throw ScreenshotException('Screenshot path is null');
      }

      return path;
    } on PlatformException catch (e) {
      throw ScreenshotException('Failed to capture screenshot: ${e.message}');
    }
  }
}
