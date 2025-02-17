import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/supabase_helper.dart';

class AdminSection extends StatefulWidget {
  const AdminSection({super.key});

  @override
  State<AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<AdminSection> {
  final _inviteCodeController = TextEditingController();
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
    _listenStorage();
  }

  Future<void> _listenStorage() async {
    box.listenKey('needRefreshSettings', (value) {
      if (value) {
        _loadInviteCode();
      } else {
        _loadInviteCode(isClear: true);
      }
    });
  }

  Future<void> _loadInviteCode({bool isClear = false}) async {
    final settings = await Config.loadSettings();
    if (isClear) {
      settings['invite_code'] = '';
    }
    if (mounted) {
      setState(() {
        _inviteCodeController.text = settings['invite_code'] ?? '';
      });
    }
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget child,
    required ChangeSettings settings,
  }) {
    return Card(
      elevation: 0,
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(76),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: settings.getForegroundColor(),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required ChangeSettings settings,
    bool isPrimary = true,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: settings.getSelectedBgColor(),
          foregroundColor: settings.getCardTextColor(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: settings.getSelectedBgColor(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: settings.getSelectedBgColor()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '管理员设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: settings.getForegroundColor(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '邀请码设置',
          settings: settings,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _inviteCodeController,
                      onChanged: (text) async {
                        await Config.saveSettings({'invite_code': text});
                      },
                      style: TextStyle(color: settings.getForegroundColor()),
                      decoration: InputDecoration(
                        hintText: '设置用户邀请码后，其他用户在注册时输入该邀请码，会与该管理员设置信息绑定',
                        hintStyle: TextStyle(color: settings.getHintTextColor()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: settings.getForegroundColor().withAlpha(76),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: settings.getForegroundColor().withAlpha(76),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: settings.getSelectedBgColor(),
                          ),
                        ),
                        filled: true,
                        fillColor: settings.getBackgroundColor().withAlpha(13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                label: '设置',
                onPressed: () async {
                  if (_inviteCodeController.text.isEmpty) {
                    showHint('邀请码不能为空');
                    return;
                  }
                  showHint('设置邀请码中...', showType: 5);
                  Map<String, dynamic> settings = await Config.loadSettings();
                  String userId = settings['user_id'] ?? '';
                  await SupabaseHelper().update(
                    'my_users',
                    {'invite_code': _inviteCodeController.text},
                    updateMatchInfo: {'user_id': userId},
                  );
                  if (context.mounted) {
                    showHint('邀请码设置成功', showType: 2);
                  }
                },
                settings: settings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }
}
