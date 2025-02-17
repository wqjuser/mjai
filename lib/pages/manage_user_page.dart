import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/landscape_stateful_mixin.dart';
import 'package:tuitu/utils/password_hasher.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/user_item_view.dart';

import '../config/config.dart';
import '../json_models/user_item_data.dart';
import '../widgets/custom_dialog.dart';

class ManageUserPage extends StatefulWidget {
  const ManageUserPage({super.key});

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> with LandscapeStatefulMixin{
  final deleteSize = 240;
  List<UserItemData> userList = [];
  final TextEditingController controller = TextEditingController();
  final storage = GetStorage();

  //获取用户列表
  Future<void> getUserList() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String inviteCode = settings['register_invite_code'] ?? 'wqjuser';
    bool isLogin = settings['is_login'] ?? false;
    if (isLogin) {
      showHint('读取用户数据中...', showType: 5);
      final userListFromDatabase =
          await SupabaseHelper().query('my_users', {'register_invite_code': inviteCode}, isOrdered: true);
      for (final user in userListFromDatabase) {
        userList.add(UserItemData(
            userId: '${user['id']}',
            userName: user['name'],
            userEmail: user['email'],
            userPassword: user['password'],
            userDeviceId: user['client_id'] ?? '暂无',
            userStatus: user['is_delete']));
      }
      setState(() {});
      dismissHint();
    }
  }

  Future<void> disableUser(int index) async {
    bool isDisable = userList[index].userStatus;
    String desc = !isDisable ? '禁用用户：${userList[index].userName}' : '恢复用户：${userList[index].userName}';
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: Colors.white,
              showConfirmButton: true,
              showCancelButton: true,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: desc,
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              descColor: Colors.white,
              useScrollContent: true,
              onCancel: () {},
              onConfirm: () async {
                showHint(isDisable ? '用户恢复中...' : '用户禁用中...', showType: 5);
                await SupabaseHelper()
                    .update('my_users', {'is_delete': !isDisable}, updateMatchInfo: {'email': userList[index].userEmail});
                dismissHint();
                showHint(isDisable ? '用户恢复成功' : '用户禁用成功', showType: 2);
                userList[index].userStatus = !isDisable;
                setState(() {});
              },
            );
          });
    }
  }

  Future<void> changeUserPassword(int index) async {
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: Colors.white,
              showConfirmButton: false,
              showCancelButton: false,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: '请勿随意修改用户密码，修改后请及时通知用户。',
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              descColor: Colors.white,
              useScrollContent: true,
              maxWidth: 400,
              content: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 1, top: 1, bottom: 1),
                      child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.0),
                              ),
                              hintText: '请输入新的密码',
                              hintStyle: TextStyle(color: Colors.white))),
                    )),
                    const SizedBox(
                      width: 3,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String hashPassword = PasswordHasher.hashPassword(controller.text);
                        if (controller.text.isEmpty) {
                          showHint('用户密码不能为空');
                          return;
                        }
                        showHint('修改用户密码中...', showType: 5);
                        await SupabaseHelper().update('my_users', {'password': hashPassword},
                            updateMatchInfo: {'email': userList[index].userEmail});
                        await SupabaseHelper().updateUser(UserAttributes(password: controller.text));
                        dismissHint();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        setState(() {
                          userList[index].userPassword = hashPassword;
                          controller.text = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 176, 215, 252), // 按钮背景颜色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5), // 圆角半径
                        ),
                      ),
                      child: const Text(
                        '改密',
                        style: TextStyle(
                          color: Color.fromARGB(255, 90, 71, 229),
                          // 文字颜色
                          fontSize: 16, // 文字大小
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                  ],
                ),
              ),
            );
          });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserList();
    listenStorage();
  }

  //读取内存的键值对
  void listenStorage() {
    storage.listenKey('is_login', (value) {
      if (value) {
        getUserList();
      } else {
        if (mounted) {
          setState(() {
            userList.clear();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SafeArea(
        child: Container(
      color: settings.getBackgroundColor(),
      child: Column(
        children: [
          SizedBox(
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
                      top: BorderSide(
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
                            '用户ID',
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
                          child: Text(
                            '用户设备ID',
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
                            '用户名称',
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
                            '用户邮箱',
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '用户密码',
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
                              Tooltip(
                                message: '这里的密码并非用户原始密码',
                                child: SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: SvgPicture.asset('assets/images/tip.svg', semanticsLabel: 'tip')),
                              )
                            ],
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
                            '用户状态',
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
                      Expanded(
                        child: Center(
                          child: Text(
                            '操作',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              UserItemData user = userList[index];
              return UserItemView(
                userItemData: user,
                index: index,
                onDisableUser: (index) async {
                  await disableUser(index);
                },
                onChangePassword: (index) async {
                  await changeUserPassword(index);
                },
              );
            },
          ))
        ],
      ),
    ));
  }
}
