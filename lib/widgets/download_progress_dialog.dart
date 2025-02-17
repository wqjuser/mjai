import 'package:flutter/material.dart';
import '../config/change_settings.dart';
import '../utils/eventbus_utils.dart';

class DownloadProgressDialog extends StatefulWidget {
  final BuildContext dialogContext;
  const DownloadProgressDialog({super.key, required this.dialogContext});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  late ChangeSettings settings;

  @override
  void initState() {
    super.initState();
    settings = ChangeSettings(widget.dialogContext);
    EventBusUtil().eventBus.on<DownloadProgressEvent>().listen((event) {
      setState(() {
        _progress = event.progress;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在下载更新'),
      titleTextStyle: TextStyle(color: settings.getForegroundColor()),
      backgroundColor: settings.getBackgroundColor(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            value: _progress,
            color: settings.getSelectedBgColor(),
          ),
          const SizedBox(height: 20),
          Text(
            '${(_progress * 100).toStringAsFixed(2)}%',
            style: TextStyle(color: settings.getForegroundColor()),
          ),
        ],
      ),
    );
  }
}

class DownloadProgressEvent {
  final double progress;

  DownloadProgressEvent(this.progress);
}