import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/change_settings.dart';
import '../../../widgets/cron_schedule_dialog.dart';
import '../../../widgets/script_process_item.dart';
import '../view_models/script_workflow_view_model.dart';

class ScriptWorkflowView extends StatelessWidget {
  const ScriptWorkflowView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final viewModel = context.watch<ScriptWorkflowViewModel>();

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
            if (viewModel.scriptPath == null)
              _buildInitialState(context, settings, viewModel)
            else
              _buildScriptConfigState(context, settings, viewModel),
            if (viewModel.runningProcesses.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildRunningProcessesSection(context, settings, viewModel),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, ChangeSettings settings, ScriptWorkflowViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              // 使用FilePicker选择脚本
              viewModel.setScriptPath(await viewModel.pickScript());
            },
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

  Widget _buildScriptConfigState(BuildContext context, ChangeSettings settings, ScriptWorkflowViewModel viewModel) {
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
                  viewModel.scriptName,
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  viewModel.setScriptPath(await viewModel.pickScript());
                },
                icon: Icon(Icons.edit_rounded, color: settings.getSelectedBgColor()),
                tooltip: '更改脚本',
                iconSize: 20,
              ),
              IconButton(
                onPressed: () => viewModel.reset(),
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
                onPressed: () => _selectScheduleTime(context, settings, viewModel),
                icon: Icon(Icons.schedule_rounded, color: settings.getSelectedBgColor()),
                label: Text(
                  viewModel.scheduledTime != null
                      ? '预定时间: ${viewModel.scheduledTime!.format(context)}'
                      : '设置执行时间',
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
                value: viewModel.isRepeating,
                onChanged: viewModel.setRepeating,
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
        if (viewModel.isRepeating) ...[
          const SizedBox(height: 16),
          _buildCronScheduleSection(context, settings, viewModel),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: viewModel.isRunning
                    ? null
                    : () async {
                        if (viewModel.scheduledTime != null) {
                          viewModel.scheduleScript(() => viewModel.executeScript());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('脚本已设置定时执行')),
                          );
                        } else {
                          await viewModel.executeScript();
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
            if (viewModel.scriptTimer != null || viewModel.isRunning) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => viewModel.stopScript(),
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

  Widget _buildCronScheduleSection(BuildContext context, ChangeSettings settings, ScriptWorkflowViewModel viewModel) {
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
                  onPressed: () => _showCronScheduleDialog(context, settings, viewModel),
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
              if (viewModel.cronSchedule != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => viewModel.setCronSchedule(null),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '清除计划',
                ),
              ],
            ],
          ),
          if (viewModel.cronSchedule != null) ...[
            const SizedBox(height: 8),
            Text(
              'Cron表达式: ${viewModel.cronSchedule!.toCronExpression()}',
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

  Widget _buildRunningProcessesSection(BuildContext context, ChangeSettings settings, ScriptWorkflowViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => viewModel.toggleRunningScriptsExpanded(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  viewModel.isRunningScriptsExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
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
                    viewModel.runningProcesses.length.toString(),
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
        if (viewModel.isRunningScriptsExpanded) ...[
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                ...viewModel.runningProcesses.map((process) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ScriptProcessItem(
                        process: process,
                        onStop: () => viewModel.stopProcess(process),
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

  Future<void> _selectScheduleTime(
    BuildContext context,
    ChangeSettings settings,
    ScriptWorkflowViewModel viewModel,
  ) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: viewModel.scheduledTime ?? TimeOfDay.now(),
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
      viewModel.setScheduledTime(time);
      viewModel.scheduleScript(() => viewModel.executeScript());
    }
  }

  void _showCronScheduleDialog(
    BuildContext context,
    ChangeSettings settings,
    ScriptWorkflowViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => CronScheduleDialog(
        initialSchedule: viewModel.cronSchedule,
        onScheduleSet: viewModel.setCronSchedule,
      ),
    );
  }
}