import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import '../models/script_process.dart';

class ScriptProcessItem extends StatelessWidget {
  final ScriptProcess process;
  final Function() onStop;
  final Color textColor;

  const ScriptProcessItem({
    super.key,
    required this.process,
    required this.onStop,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Card(
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '脚本: ${path.basename(process.scriptPath)}',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '开始时间: ${_formatDateTime(process.startTime)}',
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                  if (process.isRepeating && process.cronSchedule != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '执行计划: ${process.cronSchedule!.toCronExpression()}',
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                '停止',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
