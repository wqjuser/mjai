import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/widgets/file_display_widget.dart';
import 'package:tuitu/widgets/image_preview_widget.dart';
import '../config/change_settings.dart';
import '../json_models/chat_message.dart';
import '../utils/common_methods.dart';
import 'avatar_widget.dart';
import 'file_viewer_widget.dart';
import 'markdown.dart';

class ChatItem extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final int index;
  final bool isAnswering;
  final bool isInKB;
  final Function(bool)? onAvatarTap;

  const ChatItem({
    super.key,
    required this.message,
    required this.index,
    required this.isAnswering,
    this.onRetry,
    this.onCopy,
    this.onDelete,
    this.isInKB = false,
    this.onAvatarTap,
  });

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  bool _isHovering = false;
  bool _isRetryHovering = false;
  bool _isCopyHovering = false;
  bool _isDeleteHovering = false;
  bool isDarkMode = false;
  bool isShowMenu = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return MouseRegion(
      onEnter: (event) => _setHovering(true),
      onExit: (event) => _setHovering(false),
      child: Column(
        crossAxisAlignment: widget.message.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildAvatar(settings),
          _buildMessage(settings),
          _buildActionButtons(settings),
        ],
      ),
    );
  }

  Widget _buildAvatar(ChangeSettings settings) {
    // Using a map to associate model prefixes with corresponding image paths
    String userAvatar = getAvatarImage(widget.message.model, widget.message.isSentByMe);
    return Container(
      margin: widget.message.isSentByMe ? const EdgeInsets.only(left: 6.0, right: 6.0, top: 6) : const EdgeInsets.only(right: 6.0, left: 6.0, top: 6),
      child: MouseRegion(
        onEnter: (event) => setState(() => _isHovering = true),
        onExit: (event) => setState(() => _isHovering = false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          // Aligns the label with the bottom of the avatar
          mainAxisAlignment: widget.message.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          // Align avatar to the right if sent by user
          children: [
            if (widget.message.isSentByMe) // Display model name and send time only when hovering over the avatar
              Container(
                margin: const EdgeInsets.only(left: 8.0), // Spacing between avatar and model name
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end, // Aligns the entire column to the bottom of the avatar
                      children: [
                        Text(
                          widget.message.userName, // Display the model name
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: settings.getTextColor(), // Color of the model name
                          ),
                        ),
                        if (widget.message.sendTime != null && widget.message.sendTime!.isNotEmpty)
                          Text(
                            widget.message.sendTime!, // Display the send time
                            style: TextStyle(
                              fontSize: 10,
                              color: settings.getHintTextColor(), // Color of the send time
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            InkWell(
              onTap: () => widget.onAvatarTap?.call(widget.message.isSentByMe),
              child: widget.message.isSentByMe
                  ? const AvatarWidget()
                  : ClipOval(
                      child: ExtendedImage.asset(
                      userAvatar,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    )),
            ),
            if (!widget.message.isSentByMe) // Display model name and send time
              Container(
                margin: const EdgeInsets.only(left: 8.0), // Spacing between avatar and model name
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end, // Aligns the entire column to the bottom of the avatar
                  children: [
                    Text(
                      widget.message.model, // Display the model name
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: settings.getTextColor(), // Color of the model name
                      ),
                    ),
                    if (widget.message.sendTime != null && widget.message.sendTime!.isNotEmpty)
                      Text(
                        widget.message.sendTime!, // Display the send time
                        style: TextStyle(
                          fontSize: 10,
                          color: settings.getHintTextColor(), // Color of the send time
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

  Widget _buildMessage(ChangeSettings settings) {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return isMobile
        ? InkWell(
            onDoubleTap: () {
              if (isMobile) {
                setState(() {
                  isShowMenu = !isShowMenu;
                });
              }
            },
            child: _messageWidget(settings),
          )
        : _messageWidget(settings);
  }

  Widget _messageWidget(ChangeSettings settings) {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Container(
        margin: widget.message.isSentByMe
            ? const EdgeInsets.only(left: 50.0, right: 6.0, top: 6, bottom: 6)
            : const EdgeInsets.only(right: 50.0, left: 6.0, top: 6, bottom: 6),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: widget.message.isSentByMe ? settings.getChatBgColorMe() : settings.getChatBgColorBot(),
          borderRadius: BorderRadius.circular(10.0),
          // 添加条件边框
          border: Border.all(
            color: Colors.grey.withAlpha(76), // 可以调整透明度来改变边框的明显程度
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.files != null && widget.message.files!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImageList(),
                  _buildFileList(),
                ],
              ),
            if (widget.message.text.isNotEmpty)
              if (widget.message.files != null && widget.message.files!.isNotEmpty)
                const SizedBox(
                  height: 8,
                ),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * (isMobile ? 1.0 : 0.75), // 设置最大宽度为父容器的90%
                  ),
                  child: widget.message.isSentByMe
                      ? SelectableText(
                          widget.message.fullText ?? widget.message.text,
                          style: TextStyle(color: settings.getTextColor(), fontSize: 16),
                        )
                      : MyMarkdown(
                          text: widget.message.fullText ?? widget.message.text,
                          isSendByMe: widget.message.isSentByMe,
                          isThinkModel: widget.message.model.startsWith('o1') ||
                              widget.message.model.startsWith('o3') ||
                              widget.message.model.contains('R1'),
                        ),
                );
              },
            ),
          ],
        ));
  }

  Widget _buildActionButtons(ChangeSettings settings) {
    return Visibility(
      visible: _isHovering || isShowMenu,
      maintainAnimation: true,
      // 保持动画（如果有）
      maintainState: true,
      // 保持状态
      maintainSemantics: true,
      // 保持语义
      maintainSize: true,
      // 保持原本的尺寸
      child: Row(
        mainAxisAlignment: widget.message.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start, // 控制按钮的对齐方式
        children: [
          !widget.message.isSentByMe
              ? const SizedBox(
                  width: 8,
                )
              : Container(),
          InkWell(
            onTap: () {
              widget.onRetry!();
            },
            child: MouseRegion(
              onEnter: (event) => setState(() => _isRetryHovering = true),
              onExit: (event) => setState(() => _isRetryHovering = false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: settings.getSelectedBgColor(),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(30), // 圆角半径
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3, right: 6),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/retry.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(settings.getSelectedBgColor(), BlendMode.srcIn),
                        semanticsLabel: 'tip',
                      ),
                      if (_isRetryHovering) // 仅当鼠标悬停时显示文本
                        Center(
                          child: Text(
                            ' 重试',
                            style: TextStyle(fontSize: 14, color: settings.getSelectedBgColor()),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          InkWell(
            onTap: () {
              widget.onCopy!();
            },
            child: MouseRegion(
              onEnter: (event) => setState(() => _isCopyHovering = true),
              onExit: (event) => setState(() => _isCopyHovering = false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: settings.getSelectedBgColor(),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(30), // 圆角半径
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3, right: 6),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/copy.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(settings.getSelectedBgColor(), BlendMode.srcIn),
                        semanticsLabel: 'tip',
                      ),
                      if (_isCopyHovering) // 仅当鼠标悬停时显示文本
                        Center(
                          child: Text(
                            ' 复制',
                            style: TextStyle(fontSize: 14, color: settings.getSelectedBgColor()),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          InkWell(
            onTap: () {
              widget.onDelete!();
            },
            child: MouseRegion(
              onEnter: (event) => setState(() => _isDeleteHovering = true),
              onExit: (event) => setState(() => _isDeleteHovering = false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: settings.getSelectedBgColor(),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(30), // 圆角半径
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3, right: 6),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/delete_message.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(settings.getSelectedBgColor(), BlendMode.srcIn),
                        semanticsLabel: 'tip',
                      ),
                      if (_isDeleteHovering) // 仅当鼠标悬停时显示文本
                        Center(
                          child: Text(
                            ' 删除',
                            style: TextStyle(fontSize: 14, color: settings.getSelectedBgColor()),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
          widget.message.isSentByMe
              ? const SizedBox(
                  width: 8,
                )
              : Container(),
        ],
      ),
    );
  }

  void _setHovering(bool isHovering) {
    if (widget.isInKB) {
      if (!widget.isAnswering) {
        setState(() {
          _isHovering = isHovering;
        });
      }
    } else {
      if (widget.index != 0 && !widget.isAnswering) {
        setState(() {
          _isHovering = isHovering;
        });
      }
    }
  }

  void showFileViewerDialog(String fileContent, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FileContentViewer(fileContent: fileContent, fileName: fileName);
      },
    );
  }

  Widget _buildImageList() {
    List<Widget> imageWidgets = [];
    for (var file in widget.message.files!) {
      if (isImageFile(file.file.name)) {
        imageWidgets.add(
          ImagePreviewWidget(imageUrl: file.fileUrl == '' ? file.content! : file.fileUrl),
        );
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: imageWidgets),
    );
  }

  Widget _buildFileList() {
    List<Widget> fileWidgets = [];
    for (var file in widget.message.files!) {
      // final extension = file.file.name.split('.').last;
      if (!isImageFile(file.file.name)) {
        fileWidgets.add(InkWell(
          onTap: () {
            showFileViewerDialog(file.content ?? '', file.file.name);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: FileDisplayWidget(file: file),
          ),
        ));
      }
    }
    return Column(
        mainAxisSize: MainAxisSize.min, // 让 Column 的大小包裹内容
        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中 Column 内的子项
        children: fileWidgets);
  }
}
