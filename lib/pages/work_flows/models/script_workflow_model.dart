import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/script_process.dart';
import '../../../widgets/cron_schedule_dialog.dart';

class ScriptWorkflowModel {
  String? scriptPath;
  bool isRunning = false;
  Timer? scriptTimer;
  TimeOfDay? scheduledTime;
  bool isRepeating = false;
  CronSchedule? cronSchedule;
  String? processTitle;
  Directory? currentTempDir;
  final List<ScriptProcess> runningProcesses = [];
  bool isRunningScriptsExpanded = true;

  // 重置状态
  void reset() {
    scriptPath = null;
    isRepeating = false;
    cronSchedule = null;
    scheduledTime = null;
    processTitle = null;
    scriptTimer = null;
  }

  // 添加进程
  void addProcess(ScriptProcess process) {
    runningProcesses.add(process);
  }

  // 移除进程
  void removeProcess(ScriptProcess process) {
    runningProcesses.remove(process);
  }

  // 清理临时目录
  void cleanupTempDir() {
    if (currentTempDir != null) {
      try {
        currentTempDir!.deleteSync(recursive: true);
        currentTempDir = null;
      } catch (e) {
        print('清理临时目录失败: $e');
      }
    }
  }
}