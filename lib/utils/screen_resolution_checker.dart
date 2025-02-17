import 'package:flutter/material.dart';
import 'package:tuitu/utils/common_methods.dart';

class ScreenResolutionChecker {
  static String getScreenResolution(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pixelDensity = MediaQuery.of(context).devicePixelRatio;

    // 计算屏幕总像素
    final totalPixels = screenSize.width * screenSize.height * pixelDensity * pixelDensity;
    commonPrint('屏幕分辨率为$screenSize,物理像素是$pixelDensity');
    // 定义不同分辨率的像素范围
    const fullHdPixels = 1920 * 1080; // 1080p
    const twoKPixels = 2560 * 1440; // 2K
    const fourKPixels = 3840 * 2160; // 4K

    if (totalPixels >= fourKPixels) {
      return '4K';
    } else if (totalPixels >= twoKPixels) {
      return '2K';
    } else if (totalPixels >= fullHdPixels) {
      return '1080p';
    } else {
      return 'Below 1080p';
    }
  }
}
