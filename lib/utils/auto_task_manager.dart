import 'dart:async';

class AutoTaskManager {
  Timer? _timer;
  Function(int)? _customTaskCallback;

  void startAutoTask({
    required Duration interval,
    bool autoStart = true,
    int? initialTimestamp,
    Function(int)? customTaskCallback,
  }) {
    // 如果之前有定时器，先取消它
    cancelAutoTask();

    // 设置自定义任务回调函数
    _customTaskCallback = customTaskCallback;

    // 如果 autoStart 为 false，则不自动执行任务
    if (!autoStart) return;

    _timer = Timer.periodic(interval, (timer) {
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (initialTimestamp != null && currentTimestamp - initialTimestamp >= interval.inMilliseconds) {
        // 执行自动任务
        performAutoTask(currentTimestamp);
      }
    });
  }

  void cancelAutoTask() {
    _timer?.cancel();
  }

  void performAutoTask(int currentTimestamp) {
    // 如果有自定义任务回调函数，则调用它
    _customTaskCallback?.call(currentTimestamp);
  }
}