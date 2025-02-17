import 'package:flutter/material.dart';

import '../../../../config/change_settings.dart';

Widget buildSponsorInfo(ChangeSettings settings, BuildContext context, Function(BuildContext context, bool isRegister) onTap) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: TextButton(
      onPressed: () {
        onTap(context, false);
      },
      child: Text(
        '软件对你有用？请作者喝杯咖啡☕',
        style: TextStyle(
          color: settings.getSelectedBgColor(),
          fontSize: 13,
        ),
      ),
    ),
  );
}
