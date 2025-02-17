import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' as dio;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import '../config/config.dart';
import '../utils/supabase_helper.dart';
import '../widgets/add_package_card.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/package_card.dart';
import '../widgets/package_dialog.dart';

/// 套餐管理界面

class ManagePackagesPage extends StatefulWidget {
  final bool isBuy;

  const ManagePackagesPage({super.key, required this.isBuy});

  @override
  State<ManagePackagesPage> createState() => _ManagePackagesPageState();
}

class _ManagePackagesPageState extends State<ManagePackagesPage> {
  var packages = [].obs; // 默认没有列表套餐，从数据库获取
  Map<String, dynamic> settings = {};
  final storage = GetStorage();

  //获取用户数据
  Future<void> loadSettings() async {
    settings = await Config.loadSettings();
  }

  //获取所有未删除的套餐
  Future<void> getPackages() async {
    showHint('正在获取套餐列表', showType: 5);
    Map<String, dynamic> settings = await Config.loadSettings();
    String inviteCode = settings['register_invite_code'] ?? 'wqjuser';
    String userId = settings['user_id'] ?? '';
    bool isLogin = storage.read('is_login') ?? false;
    try {
      if (GlobalParams.isAdminVersion) {
        //这里如果是管理员的版本就只获取管理员自己设置的套餐
        if (isLogin) {
          final response = await SupabaseHelper().runRPC('get_package_templates', {
            'p_invite_code': inviteCode, 'p_page': 1, 'p_page_size': 100, 'p_user_id': userId,
            'p_order_by': 'type', // 排序字段 可选
            'p_order_direction': 'ASC' // 排序方向 可选
          });
          if (response['code'] == 200) {
            packages.value = response['data']['items'];
          } else {
            showHint('获取套餐列表失败,原因是${response['message']}');
            commonPrint('获取套餐列表失败,原因是${response['message']}');
          }
        }
      } else {
        final response = await SupabaseHelper().runRPC('get_package_templates', {
          'p_invite_code': inviteCode, 'p_page': 1, 'p_page_size': 100,
          'p_order_by': 'type', // 排序字段 可选
          'p_order_direction': 'ASC' // 排序方向 可选
        });
        if (response['code'] == 200) {
          packages.value = response['data']['items'];
        } else {
          showHint('获取套餐列表失败,原因是${response['message']}');
          commonPrint('获取套餐列表失败,原因是${response['message']}');
        }
      }
      dismissHint();
    } catch (e) {
      commonPrint('获取套餐列表失败,原因是$e');
      dismissHint();
    }
  }

  //删除指定套餐,逻辑删除
  Future<void> deletePackage(int id) async {
    await SupabaseHelper().update('package_templates', {'is_delete': true}, updateMatchInfo: {'id': id});
  }

  //新增套餐
  Future<void> addPackage(Map<dynamic, dynamic> packageInfo) async {
    String userId = settings['user_id'] ?? '';
    int validityDays = 1;
    if (packageInfo['type'] == 0) {
      validityDays = 1;
    } else if (packageInfo['type'] < 4) {
      validityDays = 30;
    } else if (packageInfo['type'] < 7) {
      validityDays = 365;
    } else if (packageInfo['type'] == 7) {
      validityDays = 36500; //额外套餐有效期为100年
    }
    await SupabaseHelper().runRPC('create_package_template', {
      'p_user_id': userId,
      'p_type': packageInfo['type'],
      'p_name': packageInfo['name'],
      'p_price': packageInfo['price'],
      'p_slow_drawing_count': packageInfo['slow_drawing_count'],
      'p_fast_drawing_count': packageInfo['fast_drawing_count'],
      'p_basic_chat_count': packageInfo['basic_chat_count'],
      'p_premium_chat_count': packageInfo['premium_chat_count'],
      'p_ai_music_count': packageInfo['ai_music_count'],
      'p_ai_video_count': packageInfo['ai_video_count'],
      'p_token_count': packageInfo['token_count'],
      'p_is_unlimited_basic_chat': packageInfo['basic_chat_count'] == -1,
      'p_validity_days': validityDays,
      'p_invite_code': settings['invite_code'] ?? 'wqjuser'
    });
    getPackages(); // 刷新列表
  }

  //修改套餐
  Future<void> modifyPackage(int index) async {
    Map<dynamic, dynamic> packageInfo = packages[index];
    showAddDialog(packageInfo, isAdd: false, index: index);
  }

  //新增或修改套餐的编辑弹窗
  void showAddDialog(Map<dynamic, dynamic> packageInfo, {bool isAdd = true, int index = 0}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PackageDialog(
          packageInfo: packageInfo,
          isAdd: isAdd,
          onConfirm: (newPackageInfo) async {
            if (isAdd) {
              await addPackage(newPackageInfo);
            } else {
              int id = packages[index]['id'];
              await SupabaseHelper().update('package_templates', newPackageInfo, updateMatchInfo: {'id': id});
              setState(() {
                packages[index] = {...packages[index], ...newPackageInfo};
              });
            }
          },
        );
      },
    );
  }

  Future<void> buyPackages(String money, String packageName, String payMethod, int packageId) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    if (money == '0.0') {
      bool canFreeUse = settings['can_free_use'] ?? false;
      if (canFreeUse) {
        var response =
            await SupabaseHelper().runRPC('purchase_package', {'p_package_template_id': packageId, 'p_user_id': userId});
        if (response['code'] == 200) {
          showHint('购买成功', showType: 2);
          await Config.saveSettings({
            'can_free_use': false,
          });
          await checkUserQuota(userId); //查询用户的套餐
          await SupabaseHelper().update('my_users', {'can_free_use': false}, updateMatchInfo: {'user_id': userId});
        } else {
          showHint('购买失败,原因:${response['message']}', showType: 3);
        }
      } else {
        showHint('抱歉，您不符合购买条件。请联系管理员', showType: 3);
      }
      return;
    }
    if (money == '0.01') {
      bool isNew = settings['is_new'] ?? false;
      if (isNew) {
        var response =
            await SupabaseHelper().runRPC('purchase_package', {'p_package_template_id': packageId, 'p_user_id': userId});
        commonPrint(response);
        if (response['code'] == 200) {
          showHint('购买成功', showType: 2);
          await Config.saveSettings({
            'is_new': false,
          });
          await checkUserQuota(userId); //先查询用户的套餐
          await SupabaseHelper().update('my_users', {'is_new': false}, updateMatchInfo: {'user_id': userId});
        } else {
          showHint('购买失败,原因:${response['message']}', showType: 3);
        }
      } else {
        showHint('抱歉，您不符合购买条件。请联系管理员', showType: 3);
      }
      return;
    }
    String payName = payMethod == 'wxpay' ? '微信' : '支付宝';
    String merchantID = settings['merchant_id'] ?? '';
    String merchantKey = settings['merchant_key'] ?? '';
    String merchantUrl = settings['merchant_url'] ?? '';
    // 获取当前时间
    DateTime now = DateTime.now();
    // 使用DateFormat格式化日期
    DateFormat formatter = DateFormat('yyyy-MM-dd HH-mm-ss');
    String formatted = formatter.format(now);
    // 获取时间戳
    int timestamp = now.millisecondsSinceEpoch;
    // 组合最终的字符串
    String result = "魔镜AI--购买$packageName\n--$formatted$timestamp".removeAllWhitespace.replaceAll('-', '');
    String ip = settings['ip'] ?? '';
    Map<String, dynamic> payParams = {
      "pid": int.parse(merchantID),
      "type": payMethod,
      "out_trade_no": result,
      "notify_url": GlobalParams.notifyUrl,
      "return_url": GlobalParams.notifyUrl,
      "name": packageName,
      "money": money,
      "clientip": ip
    };
    // 使用SplayTreeMap来自动按照key值排序
    var sortedMap = SplayTreeMap<String, dynamic>.from(payParams, (key1, key2) => key1.compareTo(key2));
    // 将排序后的Map转换为URL键值对格式
    String urlParams = sortedMap.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    var bytes = utf8.encode('$urlParams$merchantKey'); // 将输入字符串转换为字节
    var digest = md5.convert(bytes); // 对字节进行MD5加密
    payParams['sign'] = digest.toString();
    payParams['sign_type'] = 'MD5';
    try {
      showHint('创建订单中，请稍后...', showType: 5);
      dio.Response response = await MyApi().createPay(merchantUrl, payParams);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        int code = response.data['code'] ?? -1;
        if (code == 1 || code == 200) {
          if (code == 1) {
            String payUrl = response.data['payurl'] ?? '';
            String qrcode = response.data['qrcode'] ?? '';
            if (qrcode != '') {
              dealPay(response, payMethod, packageName, money, payName, packageId, payParams);
            } else if (payUrl != '') {
              myLaunchUrl(Uri.parse(payUrl));
            } else {
              showHint('创建订单失败,请稍后重试', showType: 3);
              dismissHint();
            }
          } else {
            dealPay(response, payMethod, packageName, money, payName, packageId, payParams);
          }
        } else {
          dismissHint();
          showHint(response.data['msg'], showType: 3);
        }
      }
    } catch (e) {
      commonPrint(e);
      dismissHint();
    }
  }

  void dealPay(dio.Response<dynamic> response, String payMethod, String packageName, String money, String payName, int packageId,
      Map<String, dynamic> payParams) {
    String? qrcode = response.data['qrcode'];
    String? codeUrl = response.data['code_url'];
    String? tradeNo = response.data['trade_no'];
    dismissHint();
    if (codeUrl != null && codeUrl != '' && payMethod == 'alipay') {
      if (mounted) {
        showPayDialog(payName, codeUrl, tradeNo, packageId, packageName);
      }
      insertOrder(payParams, tradeNo);
    } else if (qrcode != null && qrcode != '') {
      if (mounted) {
        showPayDialog(payName, qrcode, tradeNo, packageId, packageName);
      }
      insertOrder(payParams, tradeNo);
    }
  }

  void showPayDialog(String payName, String codeUrl, String? tradeNo, int packageId, String packageName) {
    final settings = context.read<ChangeSettings>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          title: '购买$packageName',
          descColor: settings.getForegroundColor(),
          description: '请使用$payName扫描下方二维码进行支付。',
          warn: '(付款后请务必稍等30秒或者1分钟左右再点击已付款按钮)',
          warnColor: settings.getWarnTextColor(),
          titleColor: settings.getForegroundColor(),
          showCancelButton: true,
          confirmButtonText: '已付款',
          cancelButtonText: '取消',
          isConformClose: false,
          conformButtonColor: settings.getSelectedBgColor(),
          contentBackgroundColor: settings.getBackgroundColor(),
          content: buildQRCodeContent(codeUrl, payName),
          onCancel: () {},
          onConfirm: () async {
            showHint('查询订单支付状态中，请稍后...', showType: 5);
            await checkOrderInfo(tradeNo, packageId, context);
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
    listenStorage();
    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      getPackages();
    });
  }

  //读取内存的键值对
  void listenStorage() {
    storage.listenKey('curPage', (value) {
      //判断当前页面是否是其他页面跳转到购买套餐页面
      if (widget.isBuy && value == (GlobalParams.isAdminVersion ? 10 : 8)) {
        getPackages();
      }
    });
    storage.listenKey('is_login', (value) {
      if (value) {
        getPackages();
      } else {
        packages.clear();
      }
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int count = (screenWidth / 320).floor(); // 假设每个图片最小宽度为320
    Orientation orientation = MediaQuery.of(context).orientation;
    if (Platform.isMacOS || Platform.isWindows) {
      return count.clamp(3, 7); // 限制在4-10之间
    } else {
      return orientation == Orientation.landscape ? 2 : 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorSettings = context.watch<ChangeSettings>();
    final isDarkMode = getRealDarkMode(colorSettings);
    int crossAxisCount = _calculateCrossAxisCount(context);
    return Stack(
      children: [
        // 背景图片
        Positioned.fill(
          child: ExtendedImage.asset(
            'assets/images/drawer_top_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        // 毛玻璃效果只应用于内容区域
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 主内容区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Obx(() => GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 3
                      ? 0.93
                      : crossAxisCount == 4
                          ? 0.69
                          : crossAxisCount == 5
                              ? 0.7
                              : 0.79,
                ),
                itemCount: packages.length + (widget.isBuy ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index < packages.length) {
                    final package = packages[index];
                    return PackageCard(
                      package: package,
                      isAdmin: !widget.isBuy && settings['user_id'] == package['user_id'],
                      isBuyMode: widget.isBuy,
                      onEdit: () => modifyPackage(index),
                      onDelete: () {
                        setState(() {
                          int id = package['id'];
                          packages.removeAt(index);
                          deletePackage(id);
                        });
                      },
                      isDarkMode: isDarkMode,
                      onWechatPay: (context, price, name, payType, id) => buyPackages(price, name, payType, id),
                      onAlipay: (context, price, name, payType, id) => buyPackages(price, name, payType, id),
                    );
                  } else {
                    return AddPackageCard(
                      colorSettings: colorSettings,
                      onTap: () async {
                        bool isLogin = storage.read('is_login');
                        if (isLogin) {
                          showAddDialog({});
                        } else {
                          showHint('请先登录');
                        }
                      },
                      isDarkMode: isDarkMode,
                    );
                  }
                },
              )),
        ),

        // 刷新按钮浮层
        if (widget.isBuy)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                await getPackages();
              },
              tooltip: '刷新套餐',
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              child: Icon(
                Icons.refresh,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }
}
