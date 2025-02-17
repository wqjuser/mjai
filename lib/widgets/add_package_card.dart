// 添加套餐卡片组件
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/change_settings.dart';
import '../utils/common_methods.dart';

class AddPackageCard extends StatelessWidget {
  final ChangeSettings colorSettings;
  final VoidCallback onTap;
  final bool isDarkMode;

  const AddPackageCard({
    Key? key,
    required this.colorSettings,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final isDarkMode = getRealDarkMode(settings);
    return Card(
      elevation: 4,
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: (isDarkMode ? Colors.blue.shade300 : Colors.blue).withAlpha(76),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: isDarkMode ? settings.getSelectedBgColor() : Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              '添加新套餐',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
