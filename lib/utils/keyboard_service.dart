import 'package:flutter/services.dart';

class KeyboardService {
  void Function()? onF1Pressed;

  void init() {
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        onF1Pressed?.call();
        return true; // 表示事件已被处理
      }
    }
    return false; // 表示事件未被处理，可以继续传递
  }
}
