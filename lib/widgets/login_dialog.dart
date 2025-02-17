import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import '../config/config.dart';
import '../utils/common_methods.dart';
import '../utils/password_hasher.dart';

class LoginDialog extends StatefulWidget {
  final bool isRegister;
  final Function(User user, String? hashPassword, String? userName, String? inviteCode)? onSuccess;

  const LoginDialog({Key? key, this.isRegister = true, this.onSuccess}) : super(key: key);

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  late final TextEditingController userNameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController inviteCodeController;
  late final TextEditingController verificationCodeController;

  // 添加焦点节点
  late final FocusNode _userNameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  late final FocusNode _inviteCodeFocus;

  final box = GetStorage();
  bool _isRegister = true;
  bool _isResetPassword = false;
  bool _showPassword = false;
  Timer? _timer;

  // 添加账号历史记录相关变量
  List<Map<String, String>> _accountHistory = [];
  bool _isDropdownOpen = false;

  // 添加一个全局键来获取邮箱输入框的位置
  final GlobalKey _emailFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    inviteCodeController = TextEditingController();
    verificationCodeController = TextEditingController();

    // 初始化焦点节点
    _userNameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _inviteCodeFocus = FocusNode();

    _isRegister = widget.isRegister;
    _initializeControllers();
    _loadAccountHistory();
  }

  Future<void> _initializeControllers() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    if (_isRegister) {
      userNameController.text = '';
      emailController.text = '';
      passwordController.text = '';
    } else {
      emailController.text = settings['email'] ?? '';
      passwordController.text = settings['password'] ?? '';
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    inviteCodeController.dispose();
    verificationCodeController.dispose();
    // 释放焦点节点
    _userNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _inviteCodeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }



  Future<void> _handleForgotPassword() async {
    if (!isValidEmail(emailController.text)) {
      showHint('请输入正确的邮箱格式');
      return;
    }

    try {
      showHint('发送重置密码邮件中...', showType: 5);
      await SupabaseHelper().resetPasswordForEmail(
        emailController.text,
      );
      showHint('重置密码邮件已发送，请查收邮件进行密码重置', showType: 2);
      setState(() {
        _isResetPassword = false;
      });
    } catch (e) {
      showHint('发送重置密码邮件失败：$e', showType: 3);
    }
  }

  // 加载账号历史记录
  Future<void> _loadAccountHistory() async {
    final List<dynamic>? history = box.read<List>('account_history');
    if (history != null) {
      setState(() {
        _accountHistory = history.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  // 保存账号历史记录
  Future<void> _saveAccountHistory(String email, String password) async {
    final newAccount = {'email': email, 'password': password};

    // 检查是否已存在该账号
    final existingIndex = _accountHistory.indexWhere((account) => account['email'] == email);

    if (existingIndex != -1) {
      // 更新现有账号的密码
      _accountHistory[existingIndex]['password'] = password;
    } else {
      // 添加新账号
      _accountHistory.add(newAccount);
    }

    // 限制保存的账号数量，例如最多保存5个
    if (_accountHistory.length > 5) {
      _accountHistory.removeAt(0);
    }

    await box.write('account_history', _accountHistory);
  }

  // 添加处理字段提交的方法
  void _handleFieldSubmitted(String value) {
    if (_isRegister) {
      if (_userNameFocus.hasFocus) {
        _emailFocus.requestFocus();
      } else if (_emailFocus.hasFocus) {
        _passwordFocus.requestFocus();
      } else if (_passwordFocus.hasFocus) {
        _inviteCodeFocus.requestFocus();
      } else if (_inviteCodeFocus.hasFocus) {
        _handleSubmit(context);
      }
    } else {
      if (_emailFocus.hasFocus) {
        _passwordFocus.requestFocus();
      } else if (_passwordFocus.hasFocus) {
        _handleSubmit(context);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    required Function(String) onChanged,
    required ChangeSettings settings,
    bool isEmail = false,
    FocusNode? focusNode, // 添加焦点节点参数
    Function(String)? onSubmitted, // 添加提交回调参数
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          // 使用焦点节点
          obscureText: isPassword && !_showPassword,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          // 添加提交回调
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: settings.getForegroundColor(),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: settings.getForegroundColor().withAlpha(128),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                prefixIcon,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            fillColor: settings.getCardColor(),
            filled: true,
          ),
        ),
      ),
    );
  }

  // 修改邮箱输入框为下拉式组件
  Widget _buildEmailInput(ChangeSettings settings) {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Material(
      key: _emailFieldKey,
      color: Colors.transparent,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: emailController,
          focusNode: _emailFocus,
          onChanged: (content) async {
            await Config.saveSettings({'email': content});
          },
          onSubmitted: _handleFieldSubmitted,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: settings.getForegroundColor(),
          ),
          decoration: InputDecoration(
            isDense: isMobile,
            contentPadding: isMobile ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
            hintText: '邮箱',
            hintStyle: TextStyle(
              color: settings.getForegroundColor().withValues(alpha: 255 * 0.5),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.email_outlined,
                size: 20,
                color: Colors.grey,
              ),
            ),
            suffixIcon: !_isRegister && _accountHistory.isNotEmpty
                ? InkWell(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = !_isDropdownOpen;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            fillColor: settings.getCardColor(),
            filled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(ChangeSettings settings) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Column(
      children: [
        if (_isRegister)
          _buildTextField(
            controller: userNameController,
            hint: '用户名',
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (content) async {
              await Config.saveSettings({'user_name': content});
            },
            settings: settings,
            focusNode: _userNameFocus,
            // 添加焦点节点
            onSubmitted: _handleFieldSubmitted, // 添加提交回调
          ),
        if (_isRegister) SizedBox(height: isMobile ? 9 : 16),
        _buildEmailInput(settings), // 使用新的邮箱输入组件
        SizedBox(height: isMobile ? 9 : 16),
        _buildTextField(
          controller: passwordController,
          hint: '密码',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          onChanged: (content) async {
            await Config.saveSettings({'password': content});
          },
          settings: settings,
          focusNode: _passwordFocus,
          // 添加焦点节点
          onSubmitted: _handleFieldSubmitted, // 添加提交回调
        ),
        if (_isRegister) ...[
          SizedBox(height: isMobile ? 9 : 16),
          _buildTextField(
            controller: inviteCodeController,
            hint: '邀请码(选填)',
            prefixIcon: Icons.card_giftcard_outlined,
            onChanged: (content) async {
              await Config.saveSettings({'register_invite_code': content});
            },
            settings: settings,
            focusNode: _inviteCodeFocus,
            // 添加焦点节点
            onSubmitted: _handleFieldSubmitted, // 添加提交回调
          ),
        ],
        if (!_isRegister) ...[
          SizedBox(height: isMobile ? 4 : 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isResetPassword = true;
                });
              },
              child: Text(
                '忘记密码？',
                style: TextStyle(
                  color: settings.getSelectedBgColor(),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: isMobile ? 4 : 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 0 : 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleSubmit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.getSelectedBgColor(),
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 0 : 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isRegister ? '注册' : '登录',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 16),
        InkWell(
          onTap: () {
            setState(() {
              _isRegister = !_isRegister;
              _initializeControllers();
            });
          },
          child: Text(
            _isRegister ? '已有账号？点击登录' : '没有账号？点击注册',
            style: TextStyle(
              color: settings.getSelectedBgColor(),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!isValidEmail(emailController.text)) {
      showHint('请输入正确的邮箱格式');
      return;
    }

    try {
      showHint(_isRegister ? '注册中...' : '登录中...', showType: 5);
      if (_isRegister) {
        await _handleRegister(context);
      } else {
        await _handleLogin(context);
      }
    } finally {
      dismissHint();
    }
  }

  Future<void> _handleRegister(BuildContext context) async {
    String hashPassword = PasswordHasher.hashPassword(passwordController.text);
    try {
      final AuthResponse res = await SupabaseHelper().signUp(
        emailController.text,
        passwordController.text,
        {'username': userNameController.text},
      );
      final User? user = res.user;
      final Session? session = res.session;
      if (user != null) {
        Map<String, dynamic> userMetadata = user.userMetadata ?? {};
        if (userMetadata['email'] == null) {
          showHint('注册失败，原因是该邮箱已注册');
          return;
        }
      }
      if (session == null) {
        showHint('注册成功，我们已向您的邮箱发送了一封激活邮件,请前往激活,激活后再点击登录', showType: 2, showTime: 2000);
        setState(() {
          _isRegister = false;
        });
      }
      if (user != null) {
        String inviteCode = inviteCodeController.text.isEmpty ? 'wqjuser' : inviteCodeController.text;
        widget.onSuccess?.call(user, hashPassword, userNameController.text, inviteCode);
      }
    } catch (e) {
      if ('$e'.contains('User already registered')) {
        showHint('注册失败，原因是该邮箱已注册');
      } else {
        showHint('注册失败，原因是$e');
      }
      commonPrint('注册失败，原因是$e');
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    try {
      final queryUser = await SupabaseHelper().query('my_users', {'email': emailController.text});
      if (queryUser.isNotEmpty && queryUser[0]['is_delete'] == true) {
        showHint('该账户已被管理员禁用，如有疑问请联系管理员');
        return;
      }

      final AuthResponse res = await SupabaseHelper().signIn(
        emailController.text,
        passwordController.text,
      );

      final User? user = res.user;
      if (user != null) {
        // 保存账号历史记录
        await _saveAccountHistory(emailController.text, passwordController.text);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        widget.onSuccess?.call(user, null, null, null);
      }
    } on AuthException {
      showHint('登录失败,原因是用户身份验证失败,请检查账号密码是否正确');
      commonPrint('登录失败,原因是用户身份验证失败,请检查账号密码是否正确');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: settings.getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDropdownOpen = false;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部设计
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 24),
                      decoration: BoxDecoration(
                        color: settings.getSelectedBgColor(),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isResetPassword ? Icons.lock_reset : (_isRegister ? Icons.person_add_rounded : Icons.login_rounded),
                            size: isMobile ? 20 : 40,
                            color: Colors.white,
                          ),
                          SizedBox(height: isMobile ? 6 : 12),
                          Text(
                            _isResetPassword ? '重置密码' : (_isRegister ? '注册新账号' : '欢迎回来'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 表单内容
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, isMobile ? 10 : 24, 24, isMobile ? 10 : 16),
                      child: _isResetPassword ? _buildResetPasswordContent(settings) : _buildFormContent(settings),
                    ),
                  ],
                )),
          ),
          if (_isDropdownOpen && !_isRegister && _accountHistory.isNotEmpty)
            Positioned(
              top: isMobile ? 124 : 200,
              left: 24,
              right: 24,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: settings.getCardColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _accountHistory
                          .map((account) => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      emailController.text = account['email'] ?? '';
                                      passwordController.text = account['password'] ?? '';
                                      _isDropdownOpen = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            account['email'] ?? '',
                                            style: TextStyle(
                                              color: settings.getForegroundColor(),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _accountHistory.remove(account);
                                              box.write('account_history', _accountHistory);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
        ]));
  }

  // 重置密码内容构建方法
  Widget _buildResetPasswordContent(ChangeSettings settings) {
    return Column(
      children: [
        _buildTextField(
          controller: emailController,
          hint: '邮箱',
          prefixIcon: Icons.email_outlined,
          isEmail: true,
          onChanged: (_) {},
          settings: settings,
          focusNode: _emailFocus,
          onSubmitted: (_) => _handleForgotPassword(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isResetPassword = false;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '返回',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleForgotPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.getSelectedBgColor(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '发送重置邮件',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
