import 'package:flutter/material.dart';
import 'package:tuitu/services/screenshot_exception.dart';
import 'package:tuitu/services/screenshot_manager.dart';
import 'package:tuitu/utils/common_methods.dart';

import '../json_models/display.dart';
import '../widgets/screenshot_overlay.dart';

class ScreenshotService {
  final ScreenshotManager _manager = ScreenshotManager();

  Future<void> startScreenshot(BuildContext context) async {
    try {
      // 显示加载状态
      _showLoading(context);
      // 获取显示器信息
      final displays = await _manager.getDisplays();
      // 隐藏加载状态
      Navigator.of(context).pop();
      if (displays.isEmpty) {
        throw ScreenshotException('No displays found');
      }
      // 显示截图遮罩
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ScreenshotDialog(displays: displays),
      );
    } on ScreenshotException catch (e) {
      _showError(context, e.message);
    } catch (e) {
      _showError(context, 'An unexpected error occurred');
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotDialog extends StatelessWidget {
  final List<Display> displays;

  const _ScreenshotDialog({
    Key? key,
    required this.displays,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final display in displays)
          ScreenshotOverlay(
            display: display,
            onSelected: (rect) => _handleScreenshot(context, display, rect),
            onCancel: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Future<void> _handleScreenshot(
    BuildContext context,
    Display display,
    Rect rect,
  ) async {
    try {
      Navigator.of(context).pop();

      showHint('', showType: 5);


      // TODO: 根据rect裁剪图片

      Navigator.of(context).pop();

      // 将图片保存到剪贴板或执行其他操作
    } catch (e) {
      Navigator.of(context).pop();
      commonPrint('Failed to capture screenshot');
    }
  }
}
