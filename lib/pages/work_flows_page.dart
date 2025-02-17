import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tuitu/utils/common_methods.dart';
import '../config/config.dart';
import '../net/my_api.dart';
import '../widgets/image_reimagination_dialog.dart';
import 'dart:async';
import '../widgets/cron_schedule_dialog.dart';
import '../models/script_process.dart';
import '../widgets/script_process_item.dart';
import '../work_flows/flux_i2i.dart';
import '../work_flows/joy_i2t.dart';

class WorkFlowsPage extends StatefulWidget {
  const WorkFlowsPage({super.key});

  @override
  State<WorkFlowsPage> createState() => _WorkFlowsPageState();
}

class _WorkFlowsPageState extends State<WorkFlowsPage> {
  late final MyApi _api;
  String? scriptPath;
  bool isRunning = false;
  Timer? scriptTimer;
  TimeOfDay? scheduledTime;
  bool isRepeating = false;
  CronSchedule? cronSchedule;
  List<String> selectedImages = [];
  String? selectedFolder;
  int reimagineCount = 1;
  double reimagineDenoising = 0.75;
  bool isProcessing = false;
  int currentImageIndex = 0;
  int totalImages = 0;
  String? processTitle;
  Directory? _currentTempDir;
  final List<ScriptProcess> runningProcesses = [];
  bool _isRunningScriptsExpanded = true;
  bool isReverseProcessing = false;
  List<String> selectedReverseImages = [];
  String? selectedReverseFolder;
  int currentReverseIndex = 0;
  int totalReverseImages = 0;
  int useReverseType = 0;

  @override
  void initState() {
    super.initState();
    _api = MyApi();
  }

  @override
  void dispose() {
    // 清理所有运行中的进程
    for (final process in runningProcesses) {
      process.scriptTimer?.cancel();
      process.tempDir?.deleteSync(recursive: true);
    }
    super.dispose();
  }

  void _cleanupTempDir() {
    if (_currentTempDir != null) {
      try {
        _currentTempDir!.deleteSync(recursive: true);
        _currentTempDir = null;
      } catch (e) {
        commonPrint('清理临时目录失败: $e');
      }
    }
  }

  Future<void> _pickScript() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: Platform.isWindows ? ['bat', 'cmd', 'ps1'] : ['sh', 'bash', 'zsh'],
    );

    if (result != null) {
      setState(() {
        scriptPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectScheduleTime() async {
    final settings = context.read<ChangeSettings>();
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: scheduledTime ?? TimeOfDay.now(),
      cancelText: '取消',
      confirmText: '确定',
      hourLabelText: '时',
      minuteLabelText: '分',
      helpText: '选择时间',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: settings.getCardColor(),
              hourMinuteTextColor: settings.getForegroundColor(),
              dayPeriodTextColor: settings.getForegroundColor(),
              dialHandColor: settings.getSelectedBgColor(),
              dialBackgroundColor: settings.getForegroundColor().withAlpha(25),
              dialTextColor: settings.getForegroundColor(),
              entryModeIconColor: settings.getSelectedBgColor(),
              helpTextStyle: TextStyle(color: settings.getForegroundColor()),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: settings.getSelectedBgColor(),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        scheduledTime = time;
      });
      _scheduleScript();
    }
  }

  void _scheduleScript() {
    scriptTimer?.cancel();
    if (scheduledTime != null) {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime!.hour,
        scheduledTime!.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      final duration = scheduledDateTime.difference(now);
      scriptTimer = Timer(duration, () {
        _executeScript();
        if (isRepeating) {
          _startRepeatingExecution();
        }
      });
    }
  }

  void _startRepeatingExecution() {
    scriptTimer?.cancel();

    if (cronSchedule != null) {
      // 使用cron表达式进行定时
      void scheduleNext() {
        final nextTime = cronSchedule!.getNextExecutionTime();
        final now = DateTime.now();
        final duration = nextTime.difference(now);

        scriptTimer = Timer(duration, () {
          _executeScript();
          scheduleNext(); // 安排下一次执行
        });
      }

      scheduleNext();
    }
  }

  Future<void> _executeScript() async {
    if (scriptPath == null) return;

    try {
      if (!await File(scriptPath!).exists()) {
        showHint('脚本文件不存在');
      }
      path.basename(scriptPath!);
      processTitle = 'Script_${DateTime.now().millisecondsSinceEpoch}';
      final extension = path.extension(scriptPath!).toLowerCase();

      if (Platform.isWindows) {
        try {
          final scriptFullPath = path.normalize(scriptPath!).replaceAll('/', '\\');
          final scriptDir = path.dirname(scriptFullPath);

          // 创建一个临时的启动脚本
          final tempDir = await Directory.systemTemp.createTemp('script_runner_');
          final launcherPath = path.join(tempDir.path, 'run.cmd');

          // 写入启动脚本内容，添加结束提示
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
            'exit /b %ERRORLEVEL_SAVE%\r\n', // 使用 exit /b 来确保正确的退出
            flush: true,
          );

          // 执行启动脚本
          final process = await Process.start(
            'cmd',
            ['/c', 'start', 'cmd', '/k', launcherPath],
          );

          // 保存进程 ID
          processTitle = 'Script_${process.pid}';
          _currentTempDir = tempDir;

          // 不立即显示成功消息，等待脚本实际执行完成
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('脚本已启动'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          commonPrint('执行脚本失败: $e');
          setState(() {
            isRunning = false;
          });
          rethrow;
        }
      } else {
        // Unix-like systems (Linux, macOS)
        switch (extension) {
          case '.sh':
          case '.bash':
          case '.zsh':
            // 先确保脚本有执行权限
            await Process.run('chmod', ['+x', scriptPath!]);

            // 根据不同的 Unix 系统选择合适的终端模拟器
            String terminal;
            List<String> args;

            if (Platform.isMacOS) {
              // macOS 使用 Terminal.app
              terminal = 'open';
              args = ['-a', 'Terminal', scriptPath!];
            } else {
              // Linux 系统尝试多个常见的终端模拟器
              final terminals = [
                'gnome-terminal',
                'xterm',
                'konsole',
                'xfce4-terminal',
                'mate-terminal',
              ];

              terminal = 'xterm'; // 默认使用 xterm
              args = ['-e', scriptPath!];

              // 查找可用的终端模拟器
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

            // 启动终端并执行脚本
            final process = await Process.start(
              terminal,
              args,
              workingDirectory: path.dirname(scriptPath!),
              mode: ProcessStartMode.detached,
            );

            // 保存进程 ID 用于后续终止
            processTitle = process.pid.toString();
            break;

          default:
            throw '不支持的脚本类型: $extension';
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('脚本启动成功'),
          duration: Duration(seconds: 2),
        ),
      );

      // 创建新的进程对象
      final scriptProcess = ScriptProcess(
        scriptPath: scriptPath!,
        processTitle: processTitle!,
        startTime: DateTime.now(),
        tempDir: _currentTempDir,
        scriptTimer: scriptTimer,
        isRepeating: isRepeating,
        cronSchedule: cronSchedule,
        scheduledTime: scheduledTime,
      );

      setState(() {
        runningProcesses.add(scriptProcess);
        // 重置当前选择
        scriptPath = null;
        isRepeating = false;
        cronSchedule = null;
        scheduledTime = null;
        _currentTempDir = null;
        scriptTimer = null;
      });
    } catch (e) {
      if (!mounted) return;
      commonPrint(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('启动错误: $e'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isRunning = false;
      });
    }
  }

  Future<void> _stopScript() async {
    scriptTimer?.cancel();
    scriptTimer = null;

    if (processTitle != null) {
      try {
        if (Platform.isWindows) {
          // 使用多种方式尝试关闭进程
          try {
            // 1. 通过窗口标题关闭
            await Process.run('cmd', ['/c', 'taskkill /F /FI "WINDOWTITLE eq $processTitle"']);
          } catch (_) {}

          // 2. 如果有进程ID，通过PID关闭
          if (processTitle!.startsWith('Script_')) {
            final pid = processTitle!.substring(7);
            if (int.tryParse(pid) != null) {
              try {
                // 强制终止进程及其子进程
                await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
              } catch (_) {}

              // 额外尝试终止可能的子进程
              try {
                await Process.run('wmic', ['process', 'where', 'ParentProcessId=$pid', 'delete']);
              } catch (_) {}
            }
          }

          // 3. 尝试关闭所有相关的 CMD 窗口
          try {
            await Process.run('taskkill', ['/F', '/IM', 'cmd.exe', '/FI', 'WINDOWTITLE eq $processTitle*']);
          } catch (_) {}

          _cleanupTempDir();
        } else {
          // Unix 系统使用 kill 命令终止进程
          if (int.tryParse(processTitle!) != null) {
            await Process.run('kill', [processTitle!]);
            // 确保终端也被关闭
            await Process.run('pkill', ['-P', processTitle!]);
          }
        }
      } catch (e) {
        commonPrint('关闭进程失败: $e');
      }
    }

    setState(() {
      isRunning = false;
      scheduledTime = null;
      isRepeating = false;
      cronSchedule = null;
      processTitle = null;
    });
  }

  Future<void> _stopProcess(ScriptProcess process) async {
    process.scriptTimer?.cancel();

    try {
      if (Platform.isWindows) {
        // 使用多种方式尝试关闭进程
        try {
          // 1. 通过窗口标题关闭
          await Process.run('cmd', ['/c', 'taskkill /F /FI "WINDOWTITLE eq ${process.processTitle}"']);
        } catch (_) {}

        // 2. 如果有进程ID，通过PID关闭
        if (process.processTitle.startsWith('Script_')) {
          final pid = process.processTitle.substring(7);
          if (int.tryParse(pid) != null) {
            try {
              // 强制终止进程及其子进程
              await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
            } catch (_) {}

            // 额外尝试终止可能的子进程
            try {
              await Process.run('wmic', ['process', 'where', 'ParentProcessId=$pid', 'delete']);
            } catch (_) {}
          }
        }

        // 3. 尝试关闭所有相关的 CMD 窗口
        try {
          await Process.run('taskkill', ['/F', '/IM', 'cmd.exe', '/FI', 'WINDOWTITLE eq ${process.processTitle}*']);
        } catch (_) {}

        // 安全地删除临时目录
        if (process.tempDir != null) {
          try {
            if (await process.tempDir!.exists()) {
              await process.tempDir!.delete(recursive: true);
            }
          } catch (e) {
            commonPrint('删除临时目录失败: $e');
          }
        }
      } else {
        // Unix 系统使用 kill 命令终止进程
        if (int.tryParse(process.processTitle) != null) {
          try {
            await Process.run('kill', [process.processTitle]);
            // 确保终端也被关闭
            await Process.run('pkill', ['-P', process.processTitle]);
          } catch (e) {
            commonPrint('终止进程失败: $e');
          }
        }
      }
    } catch (e) {
      commonPrint('关闭进程失败: $e');
    }

    setState(() {
      runningProcesses.remove(process);
    });
  }

  void _showImageReimaginationDialog() {
    showDialog(
      context: context,
      builder: (context) => ImageReimaginationDialog(
        onImagesSelected: _handleImagesSelected,
        onFolderSelected: _handleFolderSelected,
        onReimaginationStart: (count, denoising, _) {
          setState(() {
            reimagineCount = count;
            reimagineDenoising = denoising;
          });
        },
      ),
    );
  }

  Future<void> _handleImagesSelected(List<String> imagePaths, {bool isReImagine = true}) async {
    if (isReImagine) {
      setState(() {
        isProcessing = true;
        selectedImages = imagePaths;
        totalImages = imagePaths.length;
        currentImageIndex = 0;
      });
    }

    if (isReImagine) {
      // 重绘任务
      await _uploadImages(imagePaths, isReImagine: true);
    } else {
      // 反推任务
      await reverseImageTag(imagePaths);
    }
  }

  Future<void> reverseImageTag(List<String> imagePaths) async {
    showHint('正在检查...', showType: 5);
    if (useReverseType == 0) {
      // ComfyUI反推
      Response response = await _api.cuGetSystemStats();
      if (response.statusCode == 200) {
        setState(() {
          isReverseProcessing = true;
          selectedReverseImages = imagePaths;
          totalReverseImages = imagePaths.length;
          currentReverseIndex = 0;
        });
        dismissHint();
        await _uploadImages(imagePaths, isReImagine: false);
      } else {
        showHint('ComfyUI未启动,请先启动ComfyUI');
      }
    } else {
      // SD反推
      var settings = await Config.loadSettings();
      String sdUrl = settings['sdUrl'] ?? 'http://127.0.0.1:7860';
      Response response = await _api.testSDConnection(sdUrl);
      if (response.statusCode == 200) {
        dismissHint();
        await _reverseEngineering(imagePaths);
      } else {
        showHint('SD未启动,请先启动SD');
      }
    }
  }

  Future<void> _handleFolderSelected(String folder, {bool isReImagine = true}) async {
    final dir = Directory(folder);
    final imagePaths = await dir
        .list()
        .where((entity) =>
            entity is File &&
            (entity.path.toLowerCase().endsWith('.jpg') || entity.path.toLowerCase().endsWith('.jpeg') || entity.path.toLowerCase().endsWith('.png')))
        .toList()
        .then((list) => list.whereType<File>().map((e) => e.path).toList());

    if (isReImagine) {
      setState(() {
        isProcessing = true;
        selectedImages = imagePaths;
        totalImages = imagePaths.length;
        currentImageIndex = 0;
      });
    }

    if (isReImagine) {
      // 重绘任务
      await _uploadImages(imagePaths, isReImagine: true);
    } else {
      // 反推任务
      reverseImageTag(imagePaths);
    }
  }

  Future<void> _reverseEngineering(List<String> paths) async {
    Map<String, dynamic> requestBody = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String sdUrl = settings['sdUrl'] ?? 'http://127.0.0.1:7860';
    try {
      for (String imagePath in paths) {
        requestBody['image'] = await imageToBase64(imagePath);
        requestBody['model'] = 'wd-v1-4-moat-tagger.v2';
        requestBody['threshold'] = 0.35;
        requestBody['escape_tag'] = false;
        requestBody['add_confident_as_weight'] = false;
        Response response = await _api.getTaggerTags(sdUrl, requestBody);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          String tags = '';
          Map<String, dynamic> tagsData = response.data['caption']['tag'];
          for (String key in tagsData.keys) {
            tags += '$key, ';
          }
          String saveDirectory = imagePath.substring(0, imagePath.lastIndexOf(Platform.pathSeparator));
          String reversePath = '$saveDirectory${Platform.pathSeparator}reverse_results';
          await commonCreateDirectory(reversePath);

          String fileName = path.basenameWithoutExtension(imagePath);
          String txtFilePath = '$reversePath${Platform.pathSeparator}${fileName}_sd.txt';

          File txtFile = File(txtFilePath);
          await txtFile.writeAsString(tags.trimRight().replaceAll(RegExp(r',\s*$'), ''));
          setState(() {
            currentReverseIndex++;
            if (currentReverseIndex == totalReverseImages) {
              isReverseProcessing = false;
              showHint('所有图片反推完毕', showType: 2);
            }
          });
        }
      }
    } finally {
      try {
        Response response = await _api.unloadTaggerModels(sdUrl, null);
        if (response.statusCode == 200) {
          commonPrint('反推模型卸载成功: ${response.data}');
        } else {
          commonPrint('反推模型卸载失败: ${response.statusMessage}');
        }
      } catch (e) {
        commonPrint('反推模型卸载出错: $e');
      }
    }
  }

  Future<void> _uploadImages(List<String> paths, {bool isReImagine = true}) async {
    for (String path in paths) {
      try {
        final result = await _api.cuUploadImage(path);
        if (result.statusCode == 200) {
          String fileName = result.data['name'];
          if (isReImagine) {
            // 重绘
            final prompt = fluxI2I;
            prompt['44']['inputs']['image'] = fileName;
            prompt['59']['inputs']['batch_size'] = reimagineCount;
            prompt['17']['inputs']['denoise'] = reimagineDenoising;
            prompt['25']['inputs']['noise_seed'] = generate15DigitNumber();
            prompt['57']['inputs']['seed'] = generate15DigitNumber();
            prompt['64']['inputs']['filename_prefix'] = 'reimagine_';
            await cuGetImages(prompt);
            setState(() {
              currentImageIndex++;
              if (currentImageIndex == totalImages) {
                isProcessing = false;
                showHint('所有图片重绘完毕', showType: 2);
              }
            });
          } else {
            // 反推
            final prompt = joyI2t;
            prompt['1']['inputs']['image'] = fileName;
            String baseFileName = fileName.split('.')[0];
            prompt['19']['inputs']['filename_prefix'] = '${baseFileName}_cu';

            String saveDirectory = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
            String reversePath = '$saveDirectory${Platform.pathSeparator}reverse_results';
            await commonCreateDirectory(reversePath);
            prompt['19']['inputs']['path'] = reversePath;
            await cuGetImages(prompt, isReImagine: false);
            setState(() {
              currentReverseIndex++;
              if (currentReverseIndex == totalReverseImages) {
                isReverseProcessing = false;
                showHint('所有图片反推完毕', showType: 2);
              }
            });
          }
        }
      } catch (e) {
        commonPrint('上传图片失败: $e');
      }
    }
  }

  void _showReverseEngineeringDialog() {
    showDialog(
      context: context,
      builder: (context) => ImageReimaginationDialog(
        title: '图片反推设置',
        icon: Icons.psychology_rounded,
        showReimaginationSettings: false,
        onImagesSelected: (paths) => _handleImagesSelected(paths, isReImagine: false),
        onFolderSelected: (folder) => _handleFolderSelected(folder, isReImagine: false),
        onReimaginationStart: (_, __, reverseType) {
          setState(() {
            useReverseType = reverseType;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Container(
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScriptWorkflow(settings),
              const SizedBox(height: 20),
              _buildImageReimaginationWorkflow(settings),
              const SizedBox(height: 16),
              _buildReverseEngineeringWorkflow(settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScriptWorkflow(ChangeSettings settings) {
    return Card(
      color: settings.getBackgroundColor(),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  color: settings.getForegroundColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '通用脚本工作流',
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (scriptPath == null) _buildInitialState(settings) else _buildScriptConfigState(settings),
            if (runningProcesses.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildRunningProcessesSection(settings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(ChangeSettings settings) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: _pickScript,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('选择脚本', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: settings.getSelectedBgColor(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptConfigState(ChangeSettings settings) {
    if (scriptPath == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: settings.getForegroundColor().withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: settings.getForegroundColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path.basename(scriptPath!),
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: _pickScript,
                icon: Icon(Icons.edit_rounded, color: settings.getSelectedBgColor()),
                tooltip: '更改脚本',
                iconSize: 20,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    scriptPath = null;
                    isRepeating = false;
                    cronSchedule = null;
                    scheduledTime = null;
                  });
                },
                icon: Icon(Icons.close_rounded, color: settings.getSelectedBgColor()),
                tooltip: '取消选择',
                iconSize: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectScheduleTime,
                icon: Icon(Icons.schedule_rounded, color: settings.getSelectedBgColor()),
                label: Text(
                  scheduledTime != null ? '预定时间: ${scheduledTime!.format(context)}' : '设置执行时间',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: settings.getSelectedBgColor()),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 42,
              child: Switch(
                value: isRepeating,
                onChanged: (value) {
                  setState(() {
                    isRepeating = value;
                    if (!value) {
                      cronSchedule = null;
                    }
                  });
                },
                activeColor: settings.getSelectedBgColor(),
                activeTrackColor: settings.getSelectedBgColor().withAlpha(128),
                inactiveThumbColor: settings.getForegroundColor().withAlpha(204),
                inactiveTrackColor: settings.getForegroundColor().withAlpha(77),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '重复执行',
              style: TextStyle(
                color: settings.getForegroundColor(),
              ),
            ),
          ],
        ),
        if (isRepeating) ...[
          const SizedBox(height: 16),
          _buildCronScheduleSection(settings),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isRunning
                    ? null
                    : () {
                        if (scheduledTime != null) {
                          _scheduleScript();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('脚本已设置定时执行')),
                          );
                        } else {
                          _executeScript();
                        }
                      },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('执行脚本', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.getSelectedBgColor(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (scriptTimer != null || isRunning) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _stopScript,
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                label: const Text('停止', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCronScheduleSection(ChangeSettings settings) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CronScheduleDialog(
                        initialSchedule: cronSchedule,
                        onScheduleSet: (schedule) {
                          setState(() {
                            cronSchedule = schedule;
                          });
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_calendar_rounded, color: settings.getSelectedBgColor()),
                  label: const Text('设置执行计划'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: settings.getSelectedBgColor(),
                    side: BorderSide(color: settings.getSelectedBgColor()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (cronSchedule != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    setState(() {
                      cronSchedule = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '清除计划',
                ),
              ],
            ],
          ),
          if (cronSchedule != null) ...[
            const SizedBox(height: 8),
            Text(
              'Cron表达式: ${cronSchedule!.toCronExpression()}',
              style: TextStyle(
                color: settings.getForegroundColor().withAlpha(179),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRunningProcessesSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isRunningScriptsExpanded = !_isRunningScriptsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _isRunningScriptsExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  color: settings.getForegroundColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  '运行中的脚本',
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: settings.getForegroundColor().withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    runningProcesses.length.toString(),
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isRunningScriptsExpanded) ...[
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                ...runningProcesses.map((process) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ScriptProcessItem(
                        process: process,
                        onStop: () => _stopProcess(process),
                        textColor: settings.getForegroundColor(),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageReimaginationWorkflow(ChangeSettings settings) {
    return Card(
      color: settings.getBackgroundColor(),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high_rounded,
                  color: settings.getForegroundColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '图片批量重绘工作流(CU-Flux)',
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isProcessing && !isReverseProcessing)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    showHint('正在检查ComfyUI状态', showType: 5);
                    Response response = await _api.cuGetSystemStats();
                    if (response.statusCode == 200) {
                      dismissHint();
                      _showImageReimaginationDialog();
                    } else {
                      showHint('ComfyUI未启动,请先启动ComfyUI');
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                  label: const Text('开始新任务', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.getSelectedBgColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else if (isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: settings.getForegroundColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: settings.getSelectedBgColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '处理进度',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalImages > 0 ? currentImageIndex / totalImages : 0,
                        backgroundColor: settings.getForegroundColor().withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          settings.getSelectedBgColor(),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currentImageIndex / $totalImages',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 14,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isProcessing = false;
                            });
                          },
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                          label: const Text('停止', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: settings.getForegroundColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '图片反推工作流正在处理中...',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReverseEngineeringWorkflow(ChangeSettings settings) {
    return Card(
      color: settings.getBackgroundColor(),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: settings.getForegroundColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '图片批量反推工作流',
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isReverseProcessing && !isProcessing)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    _showReverseEngineeringDialog();
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                  label: const Text('开始新任务', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.getSelectedBgColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else if (isReverseProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: settings.getForegroundColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: settings.getSelectedBgColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '处理进度',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalReverseImages > 0 ? currentReverseIndex / totalReverseImages : 0,
                        backgroundColor: settings.getForegroundColor().withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          settings.getSelectedBgColor(),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currentReverseIndex / $totalReverseImages',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 14,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isReverseProcessing = false;
                            });
                          },
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                          label: const Text('停止', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: settings.getForegroundColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '图片重绘工作流正在处理中...',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
