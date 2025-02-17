import 'package:flutter/services.dart';
import 'package:tuitu/utils/common_methods.dart';

class NativeScreenUtils {
  // 创建一个MethodChannel，通道名与C++代码中的一致
  static const MethodChannel _channel = MethodChannel('com.htx.nativeChannel/screenResolution');

  // 定义一个异步函数来获取屏幕分辨率
  static Future<String> getSystemScreenResolution() async {
    try {
      // 调用通道的方法并获取结果
      final String result = await _channel.invokeMethod('getSystemScreenResolution');
      return result;
    } on PlatformException catch (e) {
      // 如果出现异常，返回一个默认值或错误信息
      return "Failed to get screen resolution: '${e.message}'.";
    }
  }

  static Future<String> generateThumbnail(String videoUrl) async {
    try {
      final String thumbnailPath = await _channel.invokeMethod('getThumbnail', {'url': videoUrl});
      return thumbnailPath;
    } on PlatformException catch (e) {
      commonPrint("Failed to get screen thumbnail: '${e.message}'.");
      return '';
    }
  }
}
