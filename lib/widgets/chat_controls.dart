// ChatControls widget remains the same as before
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'chat_icon_button.dart';

class ChatControls extends StatelessWidget {
  final bool enableChatContext;
  final bool enableNet;
  final bool enableHybrid;
  final bool isOnBottom;
  final String useAIModel;
  final bool alwaysShowModelName;
  final Function(bool) onChatContextChanged;
  final VoidCallback onCleanContext;
  final VoidCallback onReturnList;
  final Function(bool) onNetChanged;
  final Function(bool) onHybridChanged;
  final VoidCallback onUploadFile;
  final VoidCallback onChatSettings;
  final VoidCallback onModelSettings;
  final VoidCallback onScrollToBottom;
  final VoidCallback onShare;
  final VoidCallback? onCapture;
  final VoidCallback onMask;
  final ChangeSettings settings;
  final bool isKnowledgeBase;

  const ChatControls(
      {Key? key,
      required this.enableChatContext,
      required this.enableNet,
      required this.isOnBottom,
      required this.useAIModel,
      required this.alwaysShowModelName,
      required this.onChatContextChanged,
      required this.onCleanContext,
      required this.onReturnList,
      required this.onNetChanged,
      required this.onUploadFile,
      required this.onChatSettings,
      required this.onModelSettings,
      required this.onScrollToBottom,
      required this.onHybridChanged,
      required this.onShare,
      required this.enableHybrid,
      required this.settings,
      this.onCapture,
      required this.onMask,
      this.isKnowledgeBase = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if ((Platform.isAndroid || Platform.isIOS) && MediaQuery.of(context).orientation == Orientation.portrait) ...[
          ChatIconButton(
            iconPath: 'assets/images/return.svg',
            onTap: onReturnList,
            hoverText: '返回列表',
            color: settings.getSelectedBgColor(),
          )
        ],
        Visibility(
          visible: isSupportChatContext(useAIModel),
          child: ChatIconButton(
            iconPath: 'assets/images/context.svg',
            onTap: () => onChatContextChanged(!enableChatContext),
            hoverText: enableChatContext ? '已启用聊天上下文' : '未启用聊天上下文',
            isEnabled: enableChatContext,
            color: settings.getSelectedBgColor(),
          ),
        ),
        Visibility(
            visible: isSupportChatContext(useAIModel),
            child: ChatIconButton(
              iconPath: 'assets/images/delete_context.svg',
              onTap: onCleanContext,
              hoverText: '清除聊天上下文',
              color: settings.getSelectedBgColor(),
            )),
        Visibility(
          visible: !useAIModel.contains('联网') && !useAIModel.contains('o1'),
          child: ChatIconButton(
            iconPath: 'assets/images/net.svg',
            onTap: () => onNetChanged(!enableNet),
            hoverText: enableNet ? '已启用聊天联网' : '未启用聊天联网',
            isEnabled: enableNet,
            color: settings.getSelectedBgColor(),
          ),
        ),
        Visibility(
          visible: !isKnowledgeBase,
          child: ChatIconButton(
            iconPath: 'assets/images/upload_file.svg',
            onTap: onUploadFile,
            hoverText: '上传文件',
            color: settings.getSelectedBgColor(),
          ),
        ),
        Visibility(
            visible: !isKnowledgeBase,
            child: ChatIconButton(
              iconPath: 'assets/images/set.svg',
              onTap: onChatSettings,
              hoverText: '当前聊天设置',
              color: settings.getSelectedBgColor(),
            )),
        ChatIconButton(
          iconPath: 'assets/images/model.svg',
          onTap: onModelSettings,
          hoverText: '聊天模型：$useAIModel',
          alwaysShowText: alwaysShowModelName,
          color: settings.getSelectedBgColor(),
        ),
        Visibility(
            visible: !isKnowledgeBase && Platform.isWindows,
            child: ChatIconButton(
              iconPath: 'assets/images/capture.svg',
              onTap: onCapture!,
              hoverText: '截图提问',
              color: settings.getSelectedBgColor(),
            )),
        Visibility(
            visible: false,
            child: ChatIconButton(
              iconPath: 'assets/images/yy.svg',
              onTap: onMask,
              hoverText: '面具预设',
              color: settings.getSelectedBgColor(),
            )),
        ChatIconButton(
          iconPath: 'assets/images/share.svg',
          onTap: onShare,
          hoverText: '分享聊天内容',
          color: settings.getSelectedBgColor(),
        ),
        Visibility(
            visible: isKnowledgeBase,
            child: ChatIconButton(
              iconPath: 'assets/images/hybrid.svg',
              onTap: () => onHybridChanged(!enableHybrid),
              hoverText: enableHybrid ? '已启用混合检索' : '未启用混合检索',
              isEnabled: enableHybrid,
              color: settings.getSelectedBgColor(),
            )),
        const Spacer(),
        Visibility(
          visible: !isOnBottom,
          child: ChatIconButton(
            iconPath: 'assets/images/stb.svg',
            onTap: onScrollToBottom,
            hoverText: '滚动到底部',
            color: settings.getSelectedBgColor(),
          ),
        ),
      ],
    );
  }
}
