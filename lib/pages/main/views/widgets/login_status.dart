import 'package:flutter/material.dart';
import 'package:tuitu/pages/main/views/widgets/text_button.dart';

import '../../../../config/change_settings.dart';

// 辅助方法: 构建登录状态
Widget buildLoginStatus(
    ChangeSettings settings,
    bool isLogin,
    BuildContext context,
    Function(BuildContext context, bool isRegister) onTap,
    Function(BuildContext context) onUserTap,
    String userName,
    Function(BuildContext context) onLogoutTap) {
  return Stack(
    children: [
      Center(
        child: !isLogin
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildTextButton('注册', context, onTap, settings),
                  Text(
                    ' / ',
                    style: TextStyle(
                      color: settings.getSelectedBgColor(),
                    ),
                  ),
                  buildTextButton('登录', context, onTap, settings),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      onUserTap(context);
                    },
                    child: Text(
                      '已登录: $userName',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  TextButton(
                    onPressed: () {
                      onLogoutTap(context);
                    },
                    child: Text(
                      '退出登录',
                      style: TextStyle(
                        color: settings.getSelectedBgColor(),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ],
  );
}
