import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../../models/script_process.dart';
import '../../../utils/common_methods.dart';
import '../../../widgets/cron_schedule_dialog.dart';
import '../models/script_workflow_model.dart';

class ScriptWorkflowViewModel extends ChangeNotifier {
  final ScriptWorkflowModel _model = ScriptWorkflowModel();

  // Getters
  String? get scriptPath => _model.scriptPath;
  bool get isRunning => _model.isRunning;
  Timer? get scriptTimer => _model.scriptTimer;
  TimeOfDay? get scheduledTime => _model.scheduledTime;
  bool get isRepeating => _model.isRepeating;
  CronSchedule? get cronSchedule => _model.cronSchedule;
  String? get processTitle => _model.processTitle;
  Directory? get currentTempDir => _model.currentTempDir;
  List<ScriptProcess> get runningProcesses => _model.runningProcesses;
  bool get isRunningScriptsExpanded => _model.isRunningScriptsExpanded;

  // 获取脚本名称
  String get scriptName => scriptPath != null ? path.basename(scriptPath!) : '';

  // 选择脚本
  Future<String?> pickScript() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: Platform.isWindows ? ['bat', 'cmd', 'ps1'] : ['sh', 'bash', 'zsh'],
    );

    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }

  // 设置脚本路径
  void setScriptPath(String? path) {
    _model.scriptPath = path;
    notifyListeners();
  }

  // 设置运行状态
  void setRunning(bool value) {
    _model.isRunning = value;
    notifyListeners();
  }

  // 设置定时器
  void setScriptTimer(Timer? timer) {
    _model.scriptTimer = timer;
    notifyListeners();
  }

  // 设置计划时间
  void setScheduledTime(TimeOfDay? time) {
    _model.scheduledTime = time;
    notifyListeners();
  }

  // 设置重复执行状态
  void setRepeating(bool value) {
    _model.isRepeating = value;
    if (!value) {
      _model.cronSchedule = null;
    }
    notifyListeners();
  }

  // 设置Cron计划
  void setCronSchedule(CronSchedule? schedule) {
    _model.cronSchedule = schedule;
    notifyListeners();
  }

  // 设置进程标题
  void setProcessTitle(String? title) {
    _model.processTitle = title;
    notifyListeners();
  }

  // 设置临时目录
  void setCurrentTempDir(Directory? dir) {
    _model.currentTempDir = dir;
    notifyListeners();
  }

  // 切换运行脚本展开状态
  void toggleRunningScriptsExpanded() {
    _model.isRunningScriptsExpanded = !_model.isRunningScriptsExpanded;
    notifyListeners();
  }

  // 添加进程
  void addProcess(ScriptProcess process) {
    _model.addProcess(process);
    notifyListeners();
  }

  // 移除进程
  void removeProcess(ScriptProcess process) {
    _model.removeProcess(process);
    notifyListeners();
  }

  // 清理临时目录
  void cleanupTempDir() {
    _model.cleanupTempDir();
    notifyListeners();
  }

  // 计划脚本执行
  void scheduleScript(Function executeScript) {
    _model.scriptTimer?.cancel();
    if (_model.scheduledTime != null) {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _model.scheduledTime!.hour,
        _model.scheduledTime!.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      final duration = scheduledDateTime.difference(now);
      setScriptTimer(Timer(duration, () {
        executeScript();
        if (isRepeating) {
          startRepeatingExecution(executeScript);
        }
      }));
    }
  }

  // 开始重复执行
  void startRepeatingExecution(Function executeScript) {
    _model.scriptTimer?.cancel();

    if (_model.cronSchedule != null) {
      void scheduleNext() {
        final nextTime = _model.cronSchedule!.getNextExecutionTime();
        final now = DateTime.now();
        final duration = nextTime.difference(now);

        setScriptTimer(Timer(duration, () {
          executeScript();
          scheduleNext(); // 安排下一次执行
        }));
      }

      scheduleNext();
    }
  }

  // 执行脚本
  Future<void> executeScript() async {
    if (scriptPath == null) return;

    try {
      if (!await File(scriptPath!).exists()) {
        showHint('脚本文件不存在');
        return;
      }

      setProcessTitle('Script_${DateTime.now().millisecondsSinceEpoch}');
      final extension = path.extension(scriptPath!).toLowerCase();

      if (Platform.isWindows) {
        await _executeWindowsScript();
      } else {
        await _executeUnixScript(extension);
      }

      // 创建新的进程对象
      final scriptProcess = ScriptProcess(
        scriptPath: scriptPath!,
        processTitle: processTitle!,
        startTime: DateTime.now(),
        tempDir: currentTempDir,
        scriptTimer: scriptTimer,
        isRepeating: isRepeating,
        cronSchedule: cronSchedule,
        scheduledTime: scheduledTime,
      );

      addProcess(scriptProcess);
      reset();
    } catch (e) {
      commonPrint(e.toString());
      setRunning(false);
      rethrow;
    }
  }

  // 执行Windows脚本
  Future<void> _executeWindowsScript() async {
    try {
      final scriptFullPath = path.normalize(scriptPath!).replaceAll('/', '\\');
      final scriptDir = path.dirname(scriptFullPath);

      // 创建临时启动脚本
      final tempDir = await Directory.systemTemp.createTemp('script_runner_');
      final launcherPath = path.join(tempDir.path, 'run.cmd');

      // 写入启动脚本内容
      await File(launcherPath).writeAsString(
        '@echo off\r\n'
        'chcp 65001>nul\r\n'
        'cd /d "$scriptDir"\r\n'
        'title $processTitle\r\n'
        'echo 正在执行脚本...\r\n'
        'call "$scriptFullPath"\r\n'
        'set ERRORLEVEL_SAVE=%ERRORLEVEL%\r\n'
        'if %ERRORLEVEL_SAVE% == 0 (\r\n'
        '  echo 脚本执行完成\r\n'
        ') else (\r\n'
        '  echo 脚本执行失败，错误代码：%ERRORLEVEL_SAVE%\r\n'
        '  pause\r\n'
        ')\r\n'
        'exit /b %ERRORLEVEL_SAVE%\r\n',
        flush: true,
      );

      // 执行启动脚本
      final process = await Process.start(
        'cmd',
        ['/c', 'start', 'cmd', '/k', launcherPath],
      );

      setProcessTitle('Script_${process.pid}');
      setCurrentTempDir(tempDir);
    } catch (e) {
      commonPrint('执行脚本失败: $e');
      setRunning(false);
      rethrow;
    }
  }

  // 执行Unix脚本
  Future<void> _executeUnixScript(String extension) async {
    switch (extension) {
      case '.sh':
      case '.bash':
      case '.zsh':
        // 先确保脚本有执行权限
        await Process.run('chmod', ['+x', scriptPath!]);

        String terminal;
        List<String> args;

        if (Platform.isMacOS) {
          terminal = 'open';
          args = ['-a', 'Terminal', scriptPath!];
        } else {
          final terminals = [
            'gnome-terminal',
            'xterm',
            'konsole',
            'xfce4-terminal',
            'mate-terminal',
          ];

          terminal = 'xterm';
          args = ['-e', scriptPath!];

          for (final term in terminals) {
            try {
              final result = await Process.run('which', [term]);
              if (result.exitCode == 0) {
                terminal = term;
                switch (term) {
                  case 'gnome-terminal':
                  case 'mate-terminal':
                    args = ['--', scriptPath!];
                    break;
                  case 'konsole':
                    args = ['-e', 'bash', scriptPath!];
                    break;
                  case 'xfce4-terminal':
                    args = ['-x', scriptPath!];
                    break;
                  default:
                    args = ['-e', scriptPath!];
                }
                break;
              }
            } catch (_) {
              continue;
            }
          }
        }

        final process = await Process.start(
          terminal,
          args,
          workingDirectory: path.dirname(scriptPath!),
          mode: ProcessStartMode.detached,
        );

        setProcessTitle(process.pid.toString());
        break;

      default:
        throw '不支持的脚本类型: $extension';
    }
  }

  // 停止进程
  Future<void> stopProcess(ScriptProcess process) async {
    process.scriptTimer?.cancel();

    try {
      if (Platform.isWindows) {
        await _stopWindowsProcess(process);
      } else {
        await _stopUnixProcess(process);
      }
    } catch (e) {
      commonPrint('关闭进程失败: $e');
    }

    removeProcess(process);
  }

  // 停止Windows进程
  Future<void> _stopWindowsProcess(ScriptProcess process) async {
    try {
      await Process.run('cmd', ['/c', 'taskkill /F /FI "WINDOWTITLE eq ${process.processTitle}"']);
    } catch (_) {}

    if (process.processTitle.startsWith('Script_')) {
      final pid = process.processTitle.substring(7);
      if (int.tryParse(pid) != null) {
        try {
          await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
        } catch (_) {}

        try {
          await Process.run('wmic', ['process', 'where', 'ParentProcessId=$pid', 'delete']);
        } catch (_) {}
      }
    }

    try {
      await Process.run('taskkill', ['/F', '/IM', 'cmd.exe', '/FI', 'WINDOWTITLE eq ${process.processTitle}*']);
    } catch (_) {}

    if (process.tempDir != null) {
      try {
        if (await process.tempDir!.exists()) {
          await process.tempDir!.delete(recursive: true);
        }
      } catch (e) {
        commonPrint('删除临时目录失败: $e');
      }
    }
  }

  // 停止Unix进程
  Future<void> _stopUnixProcess(ScriptProcess process) async {
    if (int.tryParse(process.processTitle) != null) {
      try {
        await Process.run('kill', [process.processTitle]);
        await Process.run('pkill', ['-P', process.processTitle]);
      } catch (e) {
        commonPrint('终止进程失败: $e');
      }
    }
  }

  // 停止脚本
  Future<void> stopScript() async {
    _model.scriptTimer?.cancel();
    setScriptTimer(null);

    if (processTitle != null) {
      try {
        if (Platform.isWindows) {
          await _stopWindowsScript();
        } else {
          await _stopUnixScript();
        }
      } catch (e) {
        commonPrint('关闭进程失败: $e');
      }
    }

    reset();
  }

  // 停止Windows脚本
  Future<void> _stopWindowsScript() async {
    try {
      await Process.run('cmd', ['/c', 'taskkill /F /FI "WINDOWTITLE eq $processTitle"']);
    } catch (_) {}

    if (processTitle!.startsWith('Script_')) {
      final pid = processTitle!.substring(7);
      if (int.tryParse(pid) != null) {
        try {
          await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
        } catch (_) {}

        try {
          await Process.run('wmic', ['process', 'where', 'ParentProcessId=$pid', 'delete']);
        } catch (_) {}
      }
    }

    try {
      await Process.run('taskkill', ['/F', '/IM', 'cmd.exe', '/FI', 'WINDOWTITLE eq $processTitle*']);
    } catch (_) {}

    cleanupTempDir();
  }

  // 停止Unix脚本
  Future<void> _stopUnixScript() async {
    if (int.tryParse(processTitle!) != null) {
      try {
        await Process.run('kill', [processTitle!]);
        await Process.run('pkill', ['-P', processTitle!]);
      } catch (e) {
        commonPrint('终止进程失败: $e');
      }
    }
  }

  // 重置状态
  void reset() {
    _model.reset();
    notifyListeners();
  }
}