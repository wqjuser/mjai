
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/change_settings.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeSettings>(
      builder: (context, settings, child) {
        final avatar = settings.userAvatar;
        return ClipOval(
          child: avatar.startsWith('http')
              ? ExtendedImage.network(
                  avatar,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                )
              : ExtendedImage.asset(
                  avatar,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
        );
      },
    );
  }
}
