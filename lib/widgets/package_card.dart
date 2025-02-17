// 套餐卡片组件

import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';

class PackageCard extends StatelessWidget {
  final Map<dynamic, dynamic> package;
  final bool isAdmin;
  final bool isBuyMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDarkMode;
  final Function(BuildContext, String, String, String, int)? onWechatPay;
  final Function(BuildContext, String, String, String, int)? onAlipay;

  const PackageCard({
    Key? key,
    required this.package,
    required this.isAdmin,
    required this.isBuyMode,
    required this.onEdit,
    required this.onDelete,
    required this.isDarkMode,
    this.onWechatPay,
    this.onAlipay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Card(
      elevation: 8,
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: isBuyMode ? () => _showPaymentDialog(context, settings) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 套餐标题和管理按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Tooltip(
                    message: package['type'] == 7 ? '套餐内包含的额度永久有效，用完为止。' : '',
                    child: Text(
                      package['name']! +
                          ((package['type'] > 3 && package['type'] < 7)
                              ? '(月额度)'
                              : package['type'] == 0
                                  ? '(一天有效)'
                                  : package['type'] == 7
                                      ? '(永久有效)'
                                      : ''),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: settings.getForegroundColor(),
                      ),
                    ),
                  )),
                  if (isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.blue,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),

              const Divider(height: 16),

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
                              _buildFeatureItem(Icons.brush, '慢速绘图', package['slow_drawing_count'].toString(), Colors.purple,
                                  itemWidth, itemHeight, settings, context),
                              const SizedBox(width: 8),
                              _buildFeatureItem(Icons.speed, '快速绘图', package['fast_drawing_count'].toString(), Colors.orange,
                                  itemWidth, itemHeight, settings, context),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildFeatureItem(Icons.chat_bubble, '基础聊天', package['basic_chat_count'].toString(), Colors.green,
                                  itemWidth, itemHeight, settings, context),
                              const SizedBox(width: 8),
                              _buildFeatureItem(Icons.chat_bubble_outline, '高级聊天', package['premium_chat_count'].toString(),
                                  Colors.blue, itemWidth, itemHeight, settings, context),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildFeatureItem(Icons.music_note, 'AI音乐', package['ai_music_count'].toString(), Colors.pink,
                                  itemWidth, itemHeight, settings, context),
                              const SizedBox(width: 8),
                              _buildFeatureItem(Icons.videocam, 'AI视频', package['ai_video_count'].toString(), Colors.red,
                                  itemWidth, itemHeight, settings, context),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildFeatureItem(Icons.token, '聊天Tokens', package['token_count'].toString(), Colors.teal,
                                  itemWidth, itemHeight, settings, context),
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

              const SizedBox(height: 16),

              // 价格展示
              InkWell(
                onTap: isBuyMode ? () => _showPaymentDialog(context, settings) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: settings.getSelectedBgColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: EasyRichText(
                    '¥${package['price']!}${(package['type'] > 3 && package['type'] < 7) ? '/月' : ''}${(package['type'] > 3 && package['type'] < 7) ? '  (省22%)' : ''}',
                    patternList: const [
                      EasyRichTextPattern(
                        targetString: '(省22%)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                    defaultStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: settings.getCardTextColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFeatureDescription(String label) {
    switch (label) {
      case '快速绘图':
        return '速度优先的AI绘图模式，约30秒左右出图\n\n适合：\n• 快速创意验证\n• 构图测试\n• 风格探索';
      case '慢速绘图':
        return '速度较慢的AI绘图模式，大约3-5分钟出图\n\n特点：\n• 出图时间较长\n• 高峰期可能要等待很久\n• 适合不着急的需求';
      case '基础聊天':
        return '基础AI对话功能\n\n包含：\n• 日常问答\n• 简单咨询\n• 基础助手功能\n• 包含的模型有\n • gpt-4o-mini, gpt-3.5全系列\n • 谷歌Gemini Pro\n • 微软必应全系列';
      case '高级聊天':
        return '进阶AI对话功能\n\n升级特性：\n• 更深度的问题分析\n• 专业领域咨询\n• 多轮上下文对话\n• 部分模型对话一次消耗的额度更高\n• 部分模型支持识别图片\n• 包含的模型有\n • 可选列表中除了基础模型之外的所有模型';
      case 'AI音乐':
        return 'AI音乐创作功能\n\n可实现：\n• 旋律生成\n• 编曲制作\n• 多种风格创作';
      case 'AI视频':
        return 'AI视频制作功能\n\n支持：\n• 视频生成';
      case '聊天Tokens':
        return '对话的可消耗额度\n\n说明：\n• 所有模型均适用\n• tokens消耗按照模型不同而不同\n• 对话内容越长消耗的tokens越多\n• 按实际使用量计算';
      default:
        return label;
    }
  }

  void _showFeatureDescription(BuildContext context, String label, Color color, ChangeSettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: settings.getBackgroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                getFeatureIcon(label),
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            _getFeatureDescription(label),
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                '知道了',
                style: TextStyle(
                  color: getRealDarkMode(settings) ? color.withAlpha(230) : color,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  IconData getFeatureIcon(String label) {
    switch (label) {
      case '快速绘图':
        return Icons.speed;
      case '慢速绘图':
        return Icons.brush;
      case '基础聊天':
        return Icons.chat_bubble;
      case '高级聊天':
        return Icons.chat_bubble_outline;
      case 'AI音乐':
        return Icons.music_note;
      case 'AI视频':
        return Icons.videocam;
      case '聊天Tokens':
        return Icons.token;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildFeatureItem(IconData icon, String label, String value, Color color, double width, double height,
      ChangeSettings changeSettings, BuildContext context) {
    bool isDarkMode = getRealDarkMode(changeSettings);
    return InkWell(
      onTap: () => _showFeatureDescription(context, label, color, changeSettings),
      child: SizedBox(
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
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, ChangeSettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: settings.getBackgroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '选择支付方式',
            style: TextStyle(
              color: settings.getForegroundColor(),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentOption(
                context,
                icon: Icons.wechat,
                label: '微信支付',
                color: const Color(0xFF07C160),
                onTap: () {
                  Navigator.pop(context);
                  double totalPrice = package['price'];
                  if (package['type'] > 3 && package['type'] <= 6) {
                    totalPrice = package['price']! * 12;
                  }
                  onWechatPay?.call(
                    context,
                    totalPrice.toString(),
                    package['name'],
                    'wxpay',
                    package['id'],
                  );
                },
                settings: settings,
              ),
              _buildPaymentOption(context, icon: Icons.payment, label: '支付宝', color: const Color(0xFF1677FF), onTap: () {
                Navigator.pop(context);
                double totalPrice = package['price'];
                if (package['type'] > 3 && package['type'] <= 6) {
                  totalPrice = package['price']! * 12;
                }
                onAlipay?.call(
                  context,
                  totalPrice.toString(),
                  package['name'],
                  'alipay',
                  package['id'],
                );
              }, settings: settings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ChangeSettings settings,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: settings.getForegroundColor(),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.grey.withAlpha(76),
    );
  }
}
