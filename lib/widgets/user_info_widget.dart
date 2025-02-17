import 'package:flutter/material.dart';

// 用户配额卡片组件
class UserQuotaCard extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final Map<String, int> quotas;
  final VoidCallback onAvatarTap;
  final VoidCallback onUserNameTap;

  const UserQuotaCard({
    Key? key,
    required this.userName,
    this.avatarUrl,
    required this.quotas,
    required this.onAvatarTap,
    required this.onUserNameTap,
  }) : super(key: key);

  String _formatQuotaValue(int value) {
    return value == -1 ? '无限' : value.toString();
  }

  String _getQuotaDisplayName(String key) {
    final Map<String, String> displayNames = {
      'token': '通用额度',
      'ai_music': 'AI音乐',
      'ai_video': 'AI视频',
      'basic_chat': '基础对话',
      'fast_drawing': '快速绘画',
      'premium_chat': '高级对话',
      'slow_drawing': '慢速绘画',
    };
    return displayNames[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 用户信息区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF5F5F5),
                    ),
                    child: avatarUrl != null
                        ? ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(
                      Icons.person_outline,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onUserNameTap,
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 额度信息区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '套餐额度',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: quotas.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getQuotaDisplayName(entry.key),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatQuotaValue(entry.value),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}