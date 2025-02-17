import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/pages/settings/view/widgets/ai_engine_section.dart';
import 'package:tuitu/pages/settings/view/widgets/drawing_engine_section.dart';
import 'package:tuitu/pages/settings/view/widgets/file_save_section.dart';
import 'package:tuitu/pages/settings/view/widgets/voice_section.dart';
import 'package:tuitu/pages/settings/view/widgets/video_section.dart';
import 'package:tuitu/pages/settings/view/widgets/music_section.dart';
import 'package:tuitu/pages/settings/view/widgets/database_section.dart';
import 'package:tuitu/pages/settings/view/widgets/oss_section.dart';
import 'package:tuitu/pages/settings/view/widgets/moonshot_section.dart';
import 'package:tuitu/pages/settings/view/widgets/translation_section.dart';
import 'package:tuitu/pages/settings/view/widgets/admin_section.dart';

import 'widgets/exit_application_section.dart';

class SettingsView extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const SettingsView({
    super.key,
    required this.state,
    required this.presenter,
  });

  @override
  Widget build(BuildContext context) {
    final watchedState = context.watch<SettingsState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (GlobalParams.isAdminVersion) ...[
            // 管理员设置
            const AdminSection(),
            const SizedBox(height: 32),
          ],
          if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
            // AI引擎设置
            AIEngineSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32)
          ],

          // 绘图引擎设置
          DrawingEngineSection(state: watchedState, presenter: presenter, box: GetStorage()),
          const SizedBox(height: 32),

          // 文件保存设置
          FileSaveSection(
            state: watchedState,
            presenter: presenter,
          ),
          const SizedBox(height: 32),
          if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
            // 视频设置
            VideoSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // 语音设置
            VoiceSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // 音乐设置
            MusicSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // 月之暗面设置
            MoonshotSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // 数据库设置
            DatabaseSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // OSS存储设置
            OSSSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),

            // 翻译设置
            TranslationSection(
              state: watchedState,
              presenter: presenter,
            ),
            const SizedBox(height: 32),
          ],
          //退出应用布局
          if (Platform.isWindows || Platform.isMacOS) ...[
            const ExitApplicationSection(),
            // const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}
