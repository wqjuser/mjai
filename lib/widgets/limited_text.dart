import 'package:flutter/material.dart';

import '../config/change_settings.dart';
import '../utils/common_methods.dart';

class LimitedText extends StatelessWidget {
  final String text;
  final int maxChars;
  final ChangeSettings settings;

  const LimitedText({super.key, required this.text, required this.maxChars, required this.settings});

  @override
  Widget build(BuildContext context) {
    String displayText = text;
    if (text.length > maxChars) {
      displayText = '${text.substring(0, maxChars)}...';
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 16,
        color: (getRealDarkMode(settings))
            ? settings.getSelectedBgColor()
            : Colors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
