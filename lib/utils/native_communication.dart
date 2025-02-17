import 'package:flutter/services.dart';
import 'package:tuitu/utils/common_methods.dart';

class NativeCommunication {
  static const platform = MethodChannel('com.htx.macos/permissions');
  static const clipboardChannel = MethodChannel('clipboard_listener');
  static const screenShotChannel = MethodChannel('com.htx.nativeChannel/screenshot');

  static Future<String?> requestAccess() async {
    try {
      final String? path = await platform.invokeMethod('requestDocumentsAccess');
      return path;
    } on PlatformException catch (e) {
      commonPrint('Error requesting documents access: ${e.message}');
      return null;
    }
  }

  static Future<String?> getMJAIPath() async {
    try {
      final String? path = await platform.invokeMethod('getMJAIPath');
      return path;
    } on PlatformException catch (e) {
      commonPrint('Error getting MJAI path: ${e.message}');
      return null;
    }
  }

  // 获取剪切板文件的方法
  static Future<List<String>?> getClipboardFiles() async {
    try {
      final result = await clipboardChannel.invokeMethod('getClipboardFiles');
      if (result == null) return null;

      // 检查结果是否为 List
      if (result is List) {
        return result.cast<String>();
      }
      return null;
    } on PlatformException catch (e) {
      commonPrint('Error getting clipboard files: ${e.message}');
      return null;
    } catch (e) {
      // 处理其他类型错误但不打印，因为普通文本复制是正常行为
      return null;
    }
  }

  // 添加截图的方法
  static Future<String?> startScreenshot() async {
    try {
      final String? path = await screenShotChannel.invokeMethod('captureScreen');
      return path;
    } on PlatformException catch (e) {
      commonPrint('截图消息$e');
      return null;
    }
  }

}