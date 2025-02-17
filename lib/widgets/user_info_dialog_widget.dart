import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/utils/supabase_helper.dart';

import '../utils/common_methods.dart';
import '../utils/file_picker_manager.dart';
import 'notched_rectangle.dart';

/// 用户信息弹窗
class UserInfoDialogWidget extends StatefulWidget {
  final String userName;
  final String userAvatar;

  const UserInfoDialogWidget({super.key, required this.userName, required this.userAvatar});

  @override
  State<UserInfoDialogWidget> createState() => _UserInfoDialogWidgetState();
}

class _UserInfoDialogWidgetState extends State<UserInfoDialogWidget> {
  String userName = '';
  String userAvatar = '';
  String userId = '';
  Map<dynamic, dynamic> package = {};
  final box = GetStorage();
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    userAvatar = widget.userAvatar;
    getUserInfo();
  }

  Future getUserInfo() async {
    var settings = await Config.loadSettings();
    userId = settings['user_id'] ?? '';
    showHint('正在获取用户信息...', showType: 5);
    final response = await SupabaseHelper().runRPC('get_user_available_quota', {'p_user_id': userId});
    if (response['code'] == 200) {
      package = response['data'];
      var commonChatNum = response['data']['total_available']['basic_chat'] == -1
          ? 1000000000
          : response['data']['total_available']['basic_chat'];
      var seniorChatNum = response['data']['total_available']['premium_chat'];
      var commonDrawNum = response['data']['total_available']['slow_drawing'];
      var seniorDrawNum = response['data']['total_available']['fast_drawing'];
      var tokens = response['data']['total_available']['token'];
      var videosNum = response['data']['total_available']['ai_video'];
      var musicsNum = response['data']['total_available']['ai_music'];
      box.write('commonChatNum', commonChatNum);
      box.write('seniorChatNum', seniorChatNum);
      box.write('commonDrawNum', commonDrawNum);
      box.write('seniorDrawNum', seniorDrawNum);
      box.write('tokens', tokens);
      box.write('musicsNum', musicsNum);
      box.write('videosNum', videosNum);
    } else {
      if (response['code'] == 404) {
        showHint('目前暂无可用额度');
      } else {
        showHint('获取用户信息失败,原因是${response['message']}');
      }
      commonPrint('获取用户信息失败,原因是${response['message']}');
    }
    dismissHint();
    setState(() {});
  }

  Widget _buildFeatureItem(IconData icon, String label, String value, Color color, double width, double height,
      ChangeSettings changeSettings, BuildContext context) {
    bool isDarkMode = getRealDarkMode(changeSettings);
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? color.withAlpha(25) : color.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? color.withAlpha(76) : color.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode ? color.withAlpha(230) : color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == "-1" ? "不限" : "$value${label.contains("Tokens") ? "" : "次"}",
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChangeSettings settings = context.watch<ChangeSettings>();
    return Dialog(
      backgroundColor: Colors.transparent, // 设置 Dialog 背景透明
      elevation: 0, // 移除阴影
      insetPadding: EdgeInsets.zero, // 移除内边距
      child: SizedBox(
        width: 324,
        height: 540,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
            top: 50,
            child: SizedBox(
              width: 324,
              height: 540,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  NotchedRectangle(
                    strokeColor: settings.getSelectedBgColor(),
                    strokeWidth: 2,
                    width: 320,
                    height: Platform.isWindows ? 455 : 462,
                    circleDiameter: 100,
                    topLeftRadius: 20,
                    topRightRadius: 20,
                    bottomLeftRadius: 20,
                    bottomRightRadius: 20,
                    backgroundColor: settings.getBackgroundColor(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60, left: 10, right: 10, bottom: 10),
                    child: Column(
                      children: [
                        Text(
                          '你好，$userName',
                          style: TextStyle(color: settings.getForegroundColor(), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '当前套餐:',
                              style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                            ),
                            const Spacer(),
                            Text(
                              '${package.isNotEmpty ? package['subscription']['package_name'] : '暂无套餐'}',
                              style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '剩余天数:',
                              style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                            ),
                            const Spacer(),
                            Text(
                              '${package.isNotEmpty ? package['subscription']['remaining_days'] : '0'}',
                              style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '当前可用额度:',
                              style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 套餐内容
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = (constraints.maxWidth - 8) / 2; // 8是两列之间的间距
                              const itemHeight = 60.0;

                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _buildFeatureItem(
                                            Icons.brush,
                                            '慢速绘图',
                                            package.isNotEmpty ? package['total_available']['slow_drawing'].toString() : '0',
                                            Colors.purple,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                        const SizedBox(width: 8),
                                        _buildFeatureItem(
                                            Icons.speed,
                                            '快速绘图',
                                            package.isNotEmpty ? package['total_available']['fast_drawing'].toString() : '0',
                                            Colors.orange,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildFeatureItem(
                                            Icons.chat_bubble,
                                            '基础聊天',
                                            package.isNotEmpty ? package['total_available']['basic_chat'].toString() : '0',
                                            Colors.green,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                        const SizedBox(width: 8),
                                        _buildFeatureItem(
                                            Icons.chat_bubble_outline,
                                            '高级聊天',
                                            package.isNotEmpty ? package['total_available']['premium_chat'].toString() : '0',
                                            Colors.blue,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildFeatureItem(
                                            Icons.music_note,
                                            'AI音乐',
                                            package.isNotEmpty ? package['total_available']['ai_music'].toString() : '0',
                                            Colors.pink,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                        const SizedBox(width: 8),
                                        _buildFeatureItem(
                                            Icons.videocam,
                                            'AI视频',
                                            package.isNotEmpty ? package['total_available']['ai_video'].toString() : '0',
                                            Colors.red,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildFeatureItem(
                                            Icons.token,
                                            '聊天Tokens',
                                            package.isNotEmpty ? package['total_available']['token'].toString() : '0',
                                            Colors.teal,
                                            itemWidth,
                                            itemHeight,
                                            settings,
                                            context),
                                        const SizedBox(width: 8),
                                        SizedBox(width: itemWidth), // 保持对称的空白占位
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          MouseRegion(
            child: Stack(
              children: [
                ClipOval(
                  child: ExtendedImage.network(
                    userAvatar != '' ? userAvatar : 'https://oss.cuttlefish.vip/aiFile/2024-11-29/avatar.png',
                    width: 99,
                    height: 99,
                    fit: BoxFit.cover,
                    cache: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: AnimatedOpacity(
                      opacity: _isHovering ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          FilePickerResult? result = await FilePickerManager().pickFiles(type: FileType.image);
                          if (result != null) {
                            showHint('头像上传中...', showType: 5);
                            File file = File(result.files.single.path!);
                            String fileType = file.path.split('.').last;
                            String userAvatarUrl = GlobalParams.filesUrl +
                                await uploadFileToALiOss(result.files.single.path!, '', file,
                                    fileType: fileType, needDelete: false);
                            dismissHint();
                            setState(() {
                              userAvatar = userAvatarUrl;
                            });
                            await settings.updateUserAvatar(userAvatarUrl);
                            var userAvatarSettings = {'user_avatar': userAvatarUrl};
                            await Config.saveSettings(userAvatarSettings);
                            Map<String, dynamic> savedSettings = await Config.loadSettings();
                            String email = savedSettings['email'] ?? '';
                            try {
                              await SupabaseHelper().update(
                                'my_users',
                                {'htx_settings': savedSettings},
                                updateMatchInfo: {'email': email},
                              );
                            } catch (e) {
                              commonPrint('数据库数据更新失败: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 99,
                          height: 99,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withAlpha(128),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )),
                )
              ],
            ),
          )
        ]),
      ),
    );
  }
}
