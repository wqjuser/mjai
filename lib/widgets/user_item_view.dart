import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/json_models/user_item_data.dart';

class UserItemView extends StatefulWidget {
  final UserItemData userItemData;

  final int index;

  final void Function(int) onDisableUser;
  final void Function(int) onChangePassword;

  const UserItemView(
      {super.key, required this.userItemData, required this.index, required this.onDisableUser, required this.onChangePassword});

  @override
  State<UserItemView> createState() => _UserItemViewState();
}

class _UserItemViewState extends State<UserItemView> {
  final deleteSize = 240;
  late UserItemData userItemData;

  @override
  void initState() {
    super.initState();
    userItemData = widget.userItemData;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SizedBox(
      height: 40,
      width: MediaQuery.of(context).size.width,
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(), // 设置内容限制为填充父布局
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: settings.getForegroundColor(), // 边框颜色
                  width: 1.0, // 边框宽度
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      userItemData.userId,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: 200,
                  child: Center(
                    child: SelectableText(
                      userItemData.userDeviceId,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 6,
                  child: Center(
                    child: SelectableText(
                      userItemData.userName,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 6,
                  child: Center(
                    child: SelectableText(
                      userItemData.userEmail,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 6,
                  child: Center(
                    child: SelectableText(
                      userItemData.userPassword,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 6,
                  child: Center(
                    child: Text(
                      userItemData.userStatus ? '已禁用' : '正常',
                      style: TextStyle(
                        color: userItemData.userStatus ? Colors.red : settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            widget.onDisableUser(widget.index);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.getSelectedBgColor(), // 按钮背景颜色
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5), // 圆角半径
                            ),
                          ),
                          child: Text(
                            userItemData.userStatus ? '恢复' : '禁用',
                            style: TextStyle(
                              color: settings.getCardTextColor(),
                              // 文字颜色
                              fontSize: 16, // 文字大小
                            ),
                          ),
                        ),
                        Visibility(
                            visible: false,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    widget.onChangePassword(widget.index);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: settings.getSelectedBgColor(), // 按钮背景颜色
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5), // 圆角半径
                                    ),
                                  ),
                                  child: Text(
                                    '改密',
                                    style: TextStyle(
                                      color: settings.getCardTextColor(),
                                      // 文字颜色
                                      fontSize: 16, // 文字大小
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
