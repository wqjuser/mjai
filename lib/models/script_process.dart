import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/cron_schedule_dialog.dart';

class ScriptProcess {
  final String scriptPath;
  final String processTitle;
  final DateTime startTime;
  final Directory? tempDir;
  Timer? scriptTimer;
  bool isRepeating;
  CronSchedule? cronSchedule;
  TimeOfDay? scheduledTime;

  ScriptProcess({
    required this.scriptPath,
    required this.processTitle,
    required this.startTime,
    this.tempDir,
    this.scriptTimer,
    this.isRepeating = false,
    this.cronSchedule,
    this.scheduledTime,
  });
}
