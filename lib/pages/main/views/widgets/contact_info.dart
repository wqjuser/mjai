import 'package:flutter/material.dart';
import 'package:tuitu/pages/main/views/widgets/qr_text_button.dart';
import '../../../../config/change_settings.dart';

// 辅助方法: 构建联系信息
Widget buildContactInfo(ChangeSettings settings, BuildContext context, Function(String text,BuildContext context) onTap) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '有问题? 联系开发者:',
          style: TextStyle(
            color: settings.getForegroundColor(),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        buildQRTextButton('QQ', context, onTap, settings),
        const SizedBox(width: 8),
        buildQRTextButton('微信', context, onTap, settings),
      ],
    ),
  );
}
