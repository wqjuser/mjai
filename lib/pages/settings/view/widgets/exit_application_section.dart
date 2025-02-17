import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'dart:io' show Platform;

class ExitApplicationSection extends StatefulWidget {
  const ExitApplicationSection({super.key});

  @override
  State<ExitApplicationSection> createState() => _ExitApplicationSectionState();
}

class _ExitApplicationSectionState extends State<ExitApplicationSection> {
  int _exitAppMode = -1;

  @override
  void initState() {
    super.initState();
    _loadExitMode();
  }

  Future<void> _loadExitMode() async {
    final settings = await Config.loadSettings();
    if (mounted) {
      setState(() {
        _exitAppMode = settings['exit_app_method'] ?? -1;
      });
    }
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget child,
    required ChangeSettings settings,
  }) {
    return Card(
      elevation: 0,
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(76),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: settings.getForegroundColor(),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExitModeOption({
    required String title,
    required String subtitle,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = _exitAppMode == value;
    return InkWell(
      onTap: () async {
        await Config.saveSettings({'exit_app_method': value});
        setState(() => _exitAppMode = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(76),
          ),
          color: isSelected ? settings.getSelectedBgColor().withAlpha(76) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: settings.getForegroundColor().withAlpha(153),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '退出应用设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: settings.getForegroundColor(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '退出模式',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildExitModeOption(
                    title: '退出时询问',
                    subtitle: '每次退出时显示确认对话框',
                    value: -1,
                    settings: settings,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildExitModeOption(
                    title: Platform.isMacOS ? '最小化到程序坞' : '最小化到系统托盘',
                    subtitle: '应用将继续在后台运行',
                    value: 0,
                    settings: settings,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildExitModeOption(
                    title: '退出应用',
                    subtitle: '完全关闭应用程序',
                    value: 1,
                    settings: settings,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
