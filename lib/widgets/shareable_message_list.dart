import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/file_picker_manager.dart';
import 'package:tuitu/widgets/markdown.dart';
import '../config/change_settings.dart';
import '../json_models/chat_message.dart';
import 'common_dropdown.dart';

//定义导出类型
enum ExportFormat { image, markdown, json }

// 定义内容块类型
enum ContentBlockType {
  text,
  code,
  image,
  table,
}

// 内容匹配类型
enum ContentMatchType { code, image, table }

class ShareableMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final String title;
  final String model;
  final int messageCount;
  final String createTime;
  final String userAvatar;

  const ShareableMessageList(
      {Key? key,
      required this.messages,
      required this.title,
      required this.model,
      required this.messageCount,
      required this.createTime,
      required this.userAvatar})
      : super(key: key);

  @override
  State<ShareableMessageList> createState() => _ShareableMessageListState();
}

class _ShareableMessageListState extends State<ShareableMessageList> {
  Set<int> selectedIndices = {};
  ExportFormat selectedFormat = ExportFormat.image;
  final ScrollController _scrollController = ScrollController();
  List<String> availableTypes = ['PNG 图片', 'Markdown 文本', 'JSON 文件'];
  String defaultType = 'PNG 图片';
  bool isPreviewVisible = false;
  String qrCodePath = 'assets/images/share_qrcode.png';

  void _scrollToFirstSelected() {
    if (selectedIndices.isEmpty) return;

    final firstIndex = selectedIndices.reduce(min);
    _scrollController.animateTo(
      firstIndex * 72.0, // 预估每个列表项的高度
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    // 初始化时选中所有可选择的消息
    selectedIndices = Set.from(List.generate(widget.messages.length, (i) => i)
        .where((i) => widget.messages[i].files == null || widget.messages[i].files!.isEmpty));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Scaffold(
      backgroundColor: settings.getBackgroundColor(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isPreviewVisible) ...[
                // 导出格式标题和选择器
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    '导出格式',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 14,
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CommonDropdownWidget(
                    dropdownData: availableTypes,
                    selectedValue: defaultType,
                    onChangeValue: (type) {
                      setState(() {
                        defaultType = type;
                        switch (type) {
                          case 'PNG 图片':
                            selectedFormat = ExportFormat.image;
                            break;
                          case 'Markdown 文本':
                            selectedFormat = ExportFormat.markdown;
                            break;
                          case 'JSON 文件':
                            selectedFormat = ExportFormat.json;
                            break;
                        }
                      });
                    },
                  ),
                ),

                // Action buttons
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                          onPressed: () => setState(() => selectedIndices.clear()),
                          label: '清除选中',
                          icon: Icons.clear_all_rounded,
                          settings: settings),
                      _buildActionButton(
                          onPressed: () {
                            setState(() {
                              selectedIndices = Set.from(List.generate(widget.messages.length, (i) => i));
                            });
                          },
                          label: '选取全部',
                          icon: Icons.select_all_rounded,
                          settings: settings),
                      _buildActionButton(
                          onPressed: () {
                            setState(() {
                              selectedIndices = Set.from(
                                  List.generate(min(widget.messages.length, 5), (i) => widget.messages.length - 1 - i).reversed);
                            });
                            _scrollToFirstSelected();
                          },
                          label: '最近几条',
                          icon: Icons.history_rounded,
                          settings: settings),
                    ],
                  ),
                ),
                // Message list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      final bool isSelectable = message.files == null || message.files!.isEmpty;
                      return InkWell(
                          onTap: isSelectable
                              ? () {
                                  setState(() {
                                    if (selectedIndices.contains(index)) {
                                      selectedIndices.remove(index);
                                    } else {
                                      selectedIndices.add(index);
                                    }
                                  });
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: settings.getBackgroundColor(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              enabled: isSelectable,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              leading: Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: selectedIndices.contains(index),
                                  onChanged: isSelectable
                                      ? (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedIndices.add(index);
                                            } else {
                                              selectedIndices.remove(index);
                                            }
                                          });
                                        }
                                      : null,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return settings.getSelectedBgColor();
                                      }
                                      if (states.contains(WidgetState.disabled)) {
                                        return Colors.grey;
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: BorderSide(
                                    color: settings.getBorderColor(),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              title: Text(
                                message.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: settings.getForegroundColor(),
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${message.userName.isNotEmpty ? message.userName : message.model} - ${message.sendTime}',
                                style: TextStyle(
                                  color: settings.getHintTextColor(),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ));
                    },
                  ),
                ),
              ],
              if (isPreviewVisible) ...[
                Expanded(
                  child: _buildPreview(settings),
                ),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedIndices.isEmpty ? Colors.grey[800] : settings.getSelectedBgColor(),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: selectedIndices.isEmpty
                        ? null
                        : () {
                            setState(() {
                              isPreviewVisible = !isPreviewVisible;
                            });
                          },
                    child: Text(
                      isPreviewVisible ? '返回' : '预览',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIndices.isEmpty ? Colors.grey[800] : settings.getSelectedBgColor(),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: selectedIndices.isEmpty
                      ? null
                      : () async {
                          showHint('正在生成分享文件...', showType: 5);
                          await _exportMessages(settings);
                          dismissHint();
                        },
                  child: const Text(
                    '导出选中的消息',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )),
              ],
            )),
      ),
    );
  }

  Widget _buildPreview(ChangeSettings settings) {
    final selectedMessages = selectedIndices.map((index) => widget.messages[index]).toList()
      ..sort((a, b) {
        DateTime? timeA = _parseDateTime(a.sendTime!);
        DateTime? timeB = _parseDateTime(b.sendTime!);
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeA.compareTo(timeB);
      });

    switch (selectedFormat) {
      case ExportFormat.image:
        return FutureBuilder<ui.Image>(
          future: ShareContentGenerator.generateImageFromMessages(
              messages: selectedMessages,
              messageCount: widget.messageCount,
              title: widget.title,
              model: widget.model,
              createTime: widget.createTime,
              userAvatar: widget.userAvatar,
              qrCodePath: qrCodePath,
              settings: settings),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('预览生成失败', style: TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('无预览内容', style: TextStyle(color: Colors.white)));
            }

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 10,
                child: CustomPaint(
                  painter: ImagePainter(snapshot.data!),
                  size: Size.infinite,
                ),
              ),
            );
          },
        );

      case ExportFormat.markdown:
        return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settings.getBackgroundColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: MyMarkdown(
                text: _generateMarkdown(selectedMessages),
              ),
            ));

      case ExportFormat.json:
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: settings.getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              _generateJson(selectedMessages),
              style: TextStyle(
                color: settings.getTextColor(),
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
    }
  }

  String _generateMarkdown(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('# 魔镜AI对话记录\n');

    for (final message in messages) {
      buffer.writeln('### ${message.userName.isNotEmpty ? message.userName : message.model} *${message.sendTime}*');
      buffer.writeln(message.text);
      buffer.writeln('\n---\n');
    }

    return buffer.toString();
  }

  String _generateJson(List<ChatMessage> messages) {
    final Map<String, dynamic> exportData = {'messages': messages.map((m) => m.toShareJson()).toList()};

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required ChangeSettings settings,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: settings.getForegroundColor(), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: settings.getForegroundColor(), fontSize: 12),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(String dateStr) {
    try {
      // 解析格式为 "2024/10/13 16:43:06" 的时间字符串
      List<String> parts = dateStr.split(' ');
      if (parts.length != 2) return null;

      List<String> dateParts = parts[0].split('-');
      List<String> timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportMessages(ChangeSettings settings) async {
    final selectedMessages = selectedIndices.map((index) => widget.messages[index]).toList()
      ..sort((a, b) {
        // 假设时间格式为 "2024-10-13 16:43:06"
        DateTime? timeA = _parseDateTime(a.sendTime!);
        DateTime? timeB = _parseDateTime(b.sendTime!);

        // 如果解析失败，将未能解析的时间排在后面
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        return timeA.compareTo(timeB);
      });

    try {
      switch (selectedFormat) {
        case ExportFormat.image:
          await _exportAsImage(selectedMessages, settings);
          break;
        case ExportFormat.markdown:
          await _exportAsMarkdown(selectedMessages, settings);
          break;
        case ExportFormat.json:
          await _exportAsJson(selectedMessages, settings);
          break;
      }
    } catch (e) {
      // Show error dialog
      showHint('导出失败,请重试', showType: 3);
      commonPrint(e);
    }
  }

  Future<void> _exportAsImage(List<ChatMessage> messages, ChangeSettings settings) async {
    final image = await ShareContentGenerator.generateImageFromMessages(
        messages: messages,
        messageCount: widget.messageCount,
        title: widget.title,
        model: widget.model,
        createTime: widget.createTime,
        userAvatar: widget.userAvatar,
        qrCodePath: qrCodePath,
        settings: settings);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    String? outputFile = await FilePickerManager().saveFile(dialogTitle: '选择分享图片保存位置:', fileName: 'share_chat.png');
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(pngBytes);
    }
  }

  Future<void> _exportAsMarkdown(List<ChatMessage> messages, ChangeSettings settings) async {
    String? outputFile = await FilePickerManager().saveFile(dialogTitle: '选择分享Markdown文件保存位置:', fileName: 'share_chat.md');
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(_generateMarkdown(messages));
    }
  }

  Future<void> _exportAsJson(List<ChatMessage> messages, ChangeSettings settings) async {
    String? outputFile = await FilePickerManager().saveFile(dialogTitle: '选择分享Json文件保存位置:', fileName: 'share_chat.json');
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(_generateMarkdown(messages));
    }
  }
}

class ShareContentGenerator {
  static final RegExp imageUrlPattern = RegExp(
    r'!\[.*?\]\((https?:\/\/[^\s<>"]+?(?:png|jpe?g|gif|webp)(?:\?[^\s<>"]*)?)\)|https?:\/\/[^\s<>"]+?(?:png|jpe?g|gif|webp)(?:\?[^\s<>"]*)?',
    caseSensitive: false,
  );
  static final RegExp codeBlockPattern = RegExp(
    r'```(\w*)\n?([\s\S]*?)```',
    multiLine: true,
  );

  static void drawTable(Canvas canvas, MarkdownTable table, Offset position, Paint borderPaint, Paint backgroundPaint,
      Paint headerBackgroundPaint, ChangeSettings settings) {
    try {
      double currentY = position.dy;
      // 绘制表格背景
      final tableRect = Rect.fromLTWH(position.dx, position.dy, table.totalWidth, table.totalHeight);
      canvas.drawRect(tableRect, backgroundPaint);
      // 绘制表头背景
      final headerRect = Rect.fromLTWH(position.dx, position.dy, table.totalWidth, table.headerHeight);
      canvas.drawRect(headerRect, headerBackgroundPaint);
      // 绘制表头
      double currentX = position.dx;
      for (int i = 0; i < table.headers[0].length; i++) {
        try {
          final cellWidth = table.columnWidths[i];
          final cellRect = Rect.fromLTWH(currentX, currentY, cellWidth, table.headerHeight);

          // 绘制单元格边框
          canvas.drawRect(cellRect, borderPaint);

          // 绘制表头文本
          final cell = table.headers[0][i];
          final textPainter = TextPainter(
            text: TextSpan(
              text: cell,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: cellWidth - 16);

          final textX = currentX + (cellWidth - textPainter.width) / 2;
          final textY = currentY + (table.headerHeight - textPainter.height) / 2;
          textPainter.paint(canvas, Offset(textX, textY));

          currentX += cellWidth;
        } catch (e) {
          commonPrint('Error drawing header cell $i: $e');
        }
      }
      currentY += table.headerHeight;
      // 绘制表格内容
      for (int rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
        try {
          final row = table.rows[rowIndex];
          currentX = position.dx;

          for (int i = 0; i < row.length; i++) {
            final cellWidth = table.columnWidths[i];
            final cellRect = Rect.fromLTWH(currentX, currentY, cellWidth, table.rowHeight);

            // 绘制单元格边框
            canvas.drawRect(cellRect, borderPaint);

            // 绘制单元格文本
            final cell = row[i];
            final textPainter = TextPainter(
              text: TextSpan(
                text: cell,
                style: TextStyle(fontSize: 14, color: settings.getTextColor()),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout(maxWidth: cellWidth - 16);

            final textX = currentX + (cellWidth - textPainter.width) / 2;
            final textY = currentY + (table.rowHeight - textPainter.height) / 2;
            textPainter.paint(canvas, Offset(textX, textY));

            currentX += cellWidth;
          }
          currentY += table.rowHeight;
        } catch (e) {
          commonPrint('Error drawing row $rowIndex: $e');
        }
      }
    } catch (e) {
      commonPrint('Error in drawTable: $e');
    }
  }

  // 图片缓存
  static final Map<String, ui.Image> _imageCache = {};

  static Future<ui.Image> generateImageFromMessages({
    required List<ChatMessage> messages,
    required String title,
    required String model,
    required int messageCount,
    required String createTime,
    required String userAvatar,
    required String qrCodePath,
    required ChangeSettings settings,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 常量定义
    const double contentWidth = 1024.0;
    const double avatarSize = 36.0;
    const double horizontalPadding = 24.0;
    const double verticalPadding = 16.0;
    const double messageSpacing = 24.0;
    const double bubblePadding = 9.0;
    const double maxBubbleWidth = 768.0;
    const double maxImageWidth = 512.0;
    const double maxImageHeight = 512.0;
    const double headerHeight = 150.0;
    const double nameTimeSpacing = 4.0;
    const double avatarBubbleSpacing = 8.0;
    const double messageHeaderHeight = 45.0; // 头像和名称区域的高度

    // 预先加载头像和二维码图片
    ui.Image? userAvatarImage = await loadNetworkImage(userAvatar);
    ui.Image? qrCodeImage = await loadLocalImage(qrCodePath);
    Map<String, ui.Image?> modelAvatarCache = {};
    // 预先加载所有图片并计算布局
    List<MessageLayout> layouts = [];
    double totalHeight = verticalPadding;

    for (var message in messages) {
      if (!modelAvatarCache.containsKey(message.model)) {
        final avatarPath = getAvatarImage(message.model, false);
        modelAvatarCache[message.model] = await loadLocalImage(avatarPath);
      }

      final layout =
          await _calculateMessageLayout(message, maxBubbleWidth, maxImageWidth, maxImageHeight, bubblePadding, settings);

      layouts.add(layout);
      // 包含头像区域和消息体的总高度
      totalHeight += messageHeaderHeight + layout.totalHeight + messageSpacing;
    }

    // 设置画布尺寸和背景
    const canvasWidth = contentWidth;
    final canvasHeight = totalHeight + headerHeight + verticalPadding;

    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      const Radius.circular(10.0),
    );

    // 绘制背景
    canvas.drawRRect(
      background,
      Paint()..color = settings.getBackgroundColor(),
    );

    // 创建用于绘制边框的 Paint 对象
    final borderPaint = Paint()
      ..color = settings.getBorderColor()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = 2.0;

    // 绘制边框
    canvas.drawRRect(
      background,
      borderPaint,
    );
    // 绘制头部背景
    final topBackground = RRect.fromLTRBAndCorners(
      0,
      0,
      contentWidth,
      headerHeight,
      topLeft: const Radius.circular(10.0),
      topRight: const Radius.circular(10.0),
      bottomLeft: Radius.zero,
      bottomRight: Radius.zero,
    );

    canvas.drawRRect(
      topBackground,
      Paint()..color = settings.getSelectedBgColor(),
    );

    // 绘制二维码区域
    const double qrCodeSize = 100.0;
    const qrRect = Rect.fromLTWH(
      horizontalPadding,
      (headerHeight - qrCodeSize) / 2,
      qrCodeSize,
      qrCodeSize,
    );

    // 绘制二维码白色背景
    final qrBackground = RRect.fromRectAndRadius(
      qrRect,
      const Radius.circular(6.0),
    );
    canvas.drawRRect(
      qrBackground,
      Paint()..color = Colors.white,
    );

    // 绘制二维码
    if (qrCodeImage != null) {
      canvas.drawImageRect(
        qrCodeImage,
        Rect.fromLTWH(0, 0, qrCodeImage.width.toDouble(), qrCodeImage.height.toDouble()),
        qrRect,
        Paint(),
      );
    }

    // 计算中间信息区域的起始位置
    const double middleStartX = horizontalPadding + qrCodeSize + 12.0;
    const infoSpacing = 10.0;
    const infoStartY = (headerHeight - (15.0 * 4 + infoSpacing * 3)) / 2;
    double currentY = infoStartY;
    // 绘制对话标题
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: 300);
    titlePainter.paint(canvas, Offset(middleStartX, currentY));
    currentY += titlePainter.height + infoSpacing;

    // 绘制模型信息
    final modelPainter = TextPainter(
      text: TextSpan(
        text: "模型: $model",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    modelPainter.layout(maxWidth: 300);
    modelPainter.paint(canvas, Offset(middleStartX, currentY));
    currentY += modelPainter.height + infoSpacing;

    // 绘制消息数量
    final countPainter = TextPainter(
      text: TextSpan(
        text: "消息数: $messageCount",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    countPainter.layout(maxWidth: 300);
    countPainter.paint(canvas, Offset(middleStartX, currentY));
    currentY += countPainter.height + infoSpacing;

    // 绘制创建时间
    final timePainter = TextPainter(
      text: TextSpan(
        text: "创建时间: $createTime",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    timePainter.layout(maxWidth: 300);
    timePainter.paint(canvas, Offset(middleStartX, currentY));
    // 绘制右侧品牌信息
    final brandNamePainter = TextPainter(
      text: const TextSpan(
        text: "魔镜AI",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    brandNamePainter.layout();

    final sloganPainter = TextPainter(
      text: const TextSpan(
        text: "让AI更好的服务于工作和生活",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    sloganPainter.layout();

    // 计算右侧文字的位置，使其右对齐且垂直居中
    final double brandTextsTotalHeight = brandNamePainter.height + sloganPainter.height + 4;
    final double brandTextsStartY = (headerHeight - brandTextsTotalHeight) / 2;

    brandNamePainter.paint(canvas, Offset(contentWidth - horizontalPadding - brandNamePainter.width, brandTextsStartY));

    sloganPainter.paint(
        canvas, Offset(contentWidth - horizontalPadding - sloganPainter.width, brandTextsStartY + brandNamePainter.height + 4));

    // 开始绘制消息内容
    double messageY = headerHeight + verticalPadding;
    // 绘制消息
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final layout = layouts[i];
      final isUser = message.userName.isNotEmpty && message.userName != '魔镜AI';

      // 计算头像位置
      double avatarX = isUser ? canvasWidth - horizontalPadding - avatarSize : horizontalPadding;

      // 绘制头像
      final avatarRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(avatarX, messageY, avatarSize, avatarSize),
        const Radius.circular(avatarSize / 2),
      );

      canvas.save();
      canvas.clipRRect(avatarRect);

      if (isUser && userAvatarImage != null) {
        canvas.drawImageRect(
          userAvatarImage,
          Rect.fromLTWH(0, 0, userAvatarImage.width.toDouble(), userAvatarImage.height.toDouble()),
          avatarRect.outerRect,
          Paint(),
        );
      } else {
        final modelAvatar = modelAvatarCache[message.model];
        if (modelAvatar != null) {
          canvas.drawImageRect(
            modelAvatar,
            Rect.fromLTWH(0, 0, modelAvatar.width.toDouble(), modelAvatar.height.toDouble()),
            avatarRect.outerRect,
            Paint(),
          );
        } else {
          canvas.drawRRect(
            avatarRect,
            Paint()..color = isUser ? Colors.blue[600]! : const Color(0xFF10A37F),
          );
        }
      }
      canvas.restore();

      // 绘制用户名和时间
      final namePainter = TextPainter(
        text: TextSpan(
          text: isUser ? message.userName : message.model,
          style: TextStyle(
            color: settings.getForegroundColor(),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();

      final timePainter = TextPainter(
        text: TextSpan(
          text: message.sendTime,
          style: TextStyle(
            color: settings.getHintTextColor(),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      timePainter.layout();

      // 计算名称和时间的位置
      double nameX, nameY, timeX, timeY;
      if (isUser) {
        // 用户消息：名称在头像左侧，右对齐
        nameX = avatarX - namePainter.width - avatarBubbleSpacing;
        nameY = messageY;
        timeX = avatarX - timePainter.width - avatarBubbleSpacing;
        timeY = messageY + nameTimeSpacing + namePainter.height;
      } else {
        // AI消息：名称在头像右侧，左对齐
        nameX = avatarX + avatarSize + avatarBubbleSpacing;
        nameY = messageY;
        timeX = avatarX + avatarSize + avatarBubbleSpacing;
        timeY = messageY + nameTimeSpacing + namePainter.height;
      }

      // 绘制名称和时间
      namePainter.paint(canvas, Offset(nameX, nameY));
      timePainter.paint(canvas, Offset(timeX, timeY));

      // 计算消息体的起始位置（在头像和信息下方）
      final infoHeight = nameTimeSpacing + namePainter.height + timePainter.height;
      final bubbleY = messageY + infoHeight + avatarBubbleSpacing;

      // 计算气泡位置
      final bubbleX = isUser ? canvasWidth - horizontalPadding - layout.bubbleWidth : horizontalPadding;

      // 绘制气泡背景
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bubbleX,
          bubbleY,
          layout.bubbleWidth,
          layout.totalHeight,
        ),
        const Radius.circular(8),
      );

      canvas.drawRRect(
        bubbleRect,
        Paint()..color = isUser ? settings.getChatBgColorMe() : settings.getChatBgColorBot(),
      );

      // 从气泡顶部开始绘制内容
      double contentY = bubbleY + bubblePadding;

      // 按顺序绘制所有内容块
      for (final block in layout.contentBlocks) {
        switch (block.type) {
          case ContentBlockType.text:
            if (block.textPainter != null) {
              block.textPainter!.paint(
                canvas,
                Offset(bubbleX + bubblePadding, contentY),
              );
              contentY += block.textPainter!.height + bubblePadding;
            }
            break;

          case ContentBlockType.image:
            if (block.image != null && block.imageWidth != null && block.imageHeight != null) {
              // 绘制图片背景（可选，增加视觉效果）
              final imageBackground = RRect.fromRectAndRadius(
                Rect.fromLTWH(bubbleX + bubblePadding, contentY, block.imageWidth!-bubblePadding, block.imageHeight!-bubblePadding),
                const Radius.circular(4.0),
              );

              canvas.drawRRect(
                imageBackground,
                Paint()..color = Colors.black.withAlpha(25),
              );

              // 绘制图片
              canvas.drawImageRect(
                block.image!,
                Rect.fromLTWH(0, 0, block.image!.width.toDouble()-bubblePadding, block.image!.height.toDouble()-bubblePadding),
                Rect.fromLTWH(bubbleX + bubblePadding, contentY, block.imageWidth!-bubblePadding, block.imageHeight!-bubblePadding),
                Paint(),
              );

              contentY += block.imageHeight! + bubblePadding;
            }
            break;

          case ContentBlockType.code:
            if (block.codeBlock != null) {
              final codeBlock = block.codeBlock!;

              // 绘制代码块主背景
              final codeBackground = RRect.fromRectAndRadius(
                Rect.fromLTWH(bubbleX + bubblePadding, contentY, codeBlock.width, codeBlock.height),
                const Radius.circular(6.0),
              );

              canvas.drawRRect(
                codeBackground,
                Paint()..color = const Color(0xFF000000),
              );

              // 如果有语言标识，绘制语言标签区域
              if (codeBlock.language.isNotEmpty) {
                // 绘制语言标签背景，带顶部圆角
                final languageBackground = RRect.fromRectAndCorners(
                  Rect.fromLTWH(
                    bubbleX + bubblePadding,
                    contentY,
                    codeBlock.width,
                    24.0,
                  ),
                  topLeft: const Radius.circular(6.0),
                  topRight: const Radius.circular(6.0),
                );

                canvas.drawRRect(
                  languageBackground,
                  Paint()..color = const Color(0xFF2D2D2D),
                );

                // 绘制语言标签文本
                codeBlock.languagePainter.paint(
                  canvas,
                  Offset(bubbleX + bubblePadding + 8, contentY + 6),
                );
              }

              // 绘制代码内容
              final codeContentY = contentY + (codeBlock.language.isNotEmpty ? 28.0 : 8.0);
              codeBlock.codePainter.paint(
                canvas,
                Offset(bubbleX + bubblePadding + 8, codeContentY),
              );

              contentY += codeBlock.height + bubblePadding;
            }
            break;
          case ContentBlockType.table:
            if (block.table != null) {
              // 准备画笔
              final borderPaint = Paint()
                ..color = block.borderColor ?? settings.getForegroundColor()
                ..style = block.borderStyle ?? PaintingStyle.stroke
                ..strokeWidth = 1.0;

              final backgroundPaint = Paint()..color = block.backgroundColor ?? settings.getBackgroundColor();

              final headerBackgroundPaint = Paint()..color = block.headerBackgroundColor ?? settings.getSelectedBgColor();

              // 绘制表格
              drawTable(canvas, block.table!, Offset(bubbleX + bubblePadding, contentY), borderPaint, backgroundPaint,
                  headerBackgroundPaint, settings);

              contentY += block.table!.totalHeight + bubblePadding;
            }
            break;
        }
      }

      // 更新下一条消息的起始位置
      messageY = bubbleY + layout.totalHeight + messageSpacing;
    }

    // 结束绘制并返回图片
    final picture = recorder.endRecording();
    return await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
  }

  // 计算消息布局
  static Future<MessageLayout> _calculateMessageLayout(
    ChatMessage message,
    double maxBubbleWidth,
    double maxImageWidth,
    double maxImageHeight,
    double bubblePadding,
    ChangeSettings settings,
  ) async {
    List<ContentBlock> contentBlocks = [];
    double totalHeight = 0;
    double bubbleWidth = 0;

    try {
      String textContent = (message.fullText != null && message.fullText!.isNotEmpty) ? message.fullText! : message.text;
      final bool isUser = message.userName.isNotEmpty && message.userName != '魔镜AI';
      // 匹配所有需要处理的内容
      List<ContentMatch> contentMatches = [];

      // 添加代码块匹配
      final codeMatches = codeBlockPattern.allMatches(textContent);
      for (final match in codeMatches) {
        contentMatches.add(ContentMatch(
          type: ContentMatchType.code,
          start: match.start,
          end: match.end,
          match: match,
        ));
      }

      // 添加图片匹配
      final imageMatches = imageUrlPattern.allMatches(textContent);
      for (final match in imageMatches) {
        contentMatches.add(ContentMatch(
          type: ContentMatchType.image,
          start: match.start,
          end: match.end,
          match: match,
        ));
      }
      // 添加表格匹配
      final tableMatches = MarkdownTableProcessor.tablePattern.allMatches(textContent);
      for (final match in tableMatches) {
        contentMatches.add(ContentMatch(
          type: ContentMatchType.table,
          start: match.start,
          end: match.end,
          match: match,
        ));
      }

      // 按起始位置排序所有匹配
      contentMatches.sort((a, b) => a.start.compareTo(b.start));

      // 处理所有内容
      int lastEnd = 0;

      for (final contentMatch in contentMatches) {
        // 处理匹配前的文本
        if (contentMatch.start > lastEnd) {
          final text = textContent.substring(lastEnd, contentMatch.start).trim();
          if (text.isNotEmpty) {
            if (!isUser) {
              // Process markdown for non-user messages
              final List<TextSpan> markdownSpans = MarkdownTextProcessor.processMarkdownText(
                text,
                TextStyle(
                  color: settings.getTextColor(),
                  fontSize: 15,
                  height: 1.5,
                ),
                Colors.blue,
              );

              final textPainter = TextPainter(
                text: TextSpan(children: markdownSpans),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
              );
              textPainter.layout(maxWidth: maxBubbleWidth - bubblePadding * 2);

              contentBlocks.add(ContentBlock.text(textPainter));
              totalHeight += textPainter.height + bubblePadding;
              bubbleWidth = max(bubbleWidth, textPainter.width + bubblePadding * 2);
            } else {
              // Regular text processing for user messages
              final textPainter = TextPainter(
                text: TextSpan(
                  text: text,
                  style: TextStyle(
                    color: settings.getTextColor(),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
              );
              textPainter.layout(maxWidth: maxBubbleWidth - bubblePadding * 2);

              contentBlocks.add(ContentBlock.text(textPainter));
              totalHeight += textPainter.height + bubblePadding;
              bubbleWidth = max(bubbleWidth, textPainter.width + bubblePadding * 2);
            }
          }
        }

        // 根据内容类型处理匹配的内容
        switch (contentMatch.type) {
          case ContentMatchType.code:
            final match = contentMatch.match;
            final language = match.group(1)?.trim() ?? '';
            final code = match.group(2)?.trim() ?? '';

            final codeBlock = await _createCodeBlock(code, language, maxBubbleWidth, bubblePadding);

            contentBlocks.add(ContentBlock.code(codeBlock));
            totalHeight += codeBlock.height + bubblePadding;
            bubbleWidth = max(bubbleWidth, codeBlock.width);
            break;

          case ContentMatchType.image:
            final match = contentMatch.match;
            String imageUrl;
            if (match.group(1) != null) {
              // Markdown 格式的图片
              imageUrl = match.group(1)!;
            } else {
              // 直接的URL链接
              imageUrl = match.group(0)!;
            }

            // 加载图片
            final image = await loadNetworkImage(imageUrl);
            if (image != null) {
              double aspectRatio = image.width / image.height;
              double imageWidth, imageHeight;

              if (aspectRatio > 1) {
                imageWidth = min(maxImageWidth, image.width.toDouble());
                imageHeight = imageWidth / aspectRatio;
              } else {
                imageHeight = min(maxImageHeight, image.height.toDouble());
                imageWidth = imageHeight * aspectRatio;
              }

              contentBlocks.add(ContentBlock.image(image, imageWidth, imageHeight));
              totalHeight += imageHeight + bubblePadding;
              bubbleWidth = max(bubbleWidth, imageWidth + bubblePadding * 2);
            }
            break;
          case ContentMatchType.table:
            final match = contentMatch.match;
            final tableText = match.group(0)!;

            // Use bubbleWidth - (bubblePadding * 2) as the maxWidth for the table
            final table = await MarkdownTableProcessor.processTable(
              tableText,
              maxBubbleWidth - bubblePadding * 2,
              TextStyle(
                color: settings.getTextColor(),
                fontSize: 14,
              ),
              TextStyle(
                color: settings.getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            );

            if (table != null) {
              contentBlocks.add(ContentBlock.table(
                table,
                PaintingStyle.stroke,
                settings.getForegroundColor(),
                settings.getBackgroundColor(),
                settings.getSelectedBgColor(),
              ));
              totalHeight += table.totalHeight + bubblePadding;
              bubbleWidth = maxBubbleWidth; // Ensure bubble width matches the maximum
            }
            break;
        }

        lastEnd = contentMatch.end;
      }

      // 处理剩余文本
      if (lastEnd < textContent.length) {
        final text = textContent.substring(lastEnd).trim();
        if (text.isNotEmpty) {
          if (!isUser) {
            // Process markdown for non-user messages
            final List<TextSpan> markdownSpans = MarkdownTextProcessor.processMarkdownText(
              text,
              TextStyle(
                color: settings.getTextColor(),
                fontSize: 15,
                height: 1.5,
              ),
              Colors.blue,
            );

            final textPainter = TextPainter(
              text: TextSpan(children: markdownSpans),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            );
            textPainter.layout(maxWidth: maxBubbleWidth - bubblePadding * 2);

            contentBlocks.add(ContentBlock.text(textPainter));
            totalHeight += textPainter.height;
            bubbleWidth = max(bubbleWidth, textPainter.width + bubblePadding * 2);
          } else {
            // Regular text processing for user messages
            final textPainter = TextPainter(
              text: TextSpan(
                text: text,
                style: TextStyle(
                  color: settings.getTextColor(),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            );
            textPainter.layout(maxWidth: maxBubbleWidth - bubblePadding * 2);
            contentBlocks.add(ContentBlock.text(textPainter));
            totalHeight += textPainter.height + bubblePadding;
            bubbleWidth = max(bubbleWidth, textPainter.width + bubblePadding * 2);
          }
        }
      }
      if (isUser) {
        totalHeight += bubblePadding + 2;
      }
      // 确保最小尺寸
      totalHeight = max(totalHeight, 40.0);
      bubbleWidth = max(bubbleWidth, 60.0);
      return MessageLayout(
        contentBlocks: contentBlocks,
        totalHeight: totalHeight,
        bubbleWidth: bubbleWidth,
      );
    } catch (e, stackTrace) {
      commonPrint('Error in _calculateMessageLayout: $e');
      commonPrint('Stack trace: $stackTrace');
      return createErrorLayout(maxBubbleWidth, bubblePadding);
    }
  }

  // 加载网络图片
  static Future<ui.Image?> loadNetworkImage(String url) async {
    try {
      final HttpClient httpClient = HttpClient();
      final Uri uri = Uri.parse(url);
      final HttpClientRequest request = await httpClient.getUrl(uri);
      final HttpClientResponse response = await request.close();
      final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      commonPrint('Error loading network image: $e');
      return null;
    }
  }

  // 加载本地图片
  static Future<ui.Image?> loadLocalImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      commonPrint('Error loading local image: $e');
      return null;
    }
  }

  // 清理图片缓存
  static void clearImageCache() {
    _imageCache.clear();
  }

  // 创建代码块布局
  static Future<CodeBlockLayout> _createCodeBlock(
    String code,
    String language,
    double maxBubbleWidth,
    double bubblePadding,
  ) async {
    // 计算代码块的实际可用宽度（与普通文本相同）
    final double maxCodeWidth = maxBubbleWidth - bubblePadding * 2;

    // 创建代码内容画笔，启用自动换行
    final codePainter = TextPainter(
      text: TextSpan(
        text: code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: null, // 允许多行
    );
    codePainter.layout(maxWidth: maxCodeWidth - 16); // 减去代码内容的左右padding(8+8)

    final languagePainter = TextPainter(
      text: TextSpan(
        text: language,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    languagePainter.layout();

    // 计算代码块的总高度
    final codeBlockHeight = 8.0 + // 顶部padding
        (language.isNotEmpty ? 24.0 : 0) + // 语言标签高度
        4.0 + // 语言标签和代码之间的间距
        codePainter.height +
        8.0; // 底部padding

    // 使用最大宽度，确保所有代码块宽度一致
    return CodeBlockLayout(
      language: language,
      code: code,
      width: maxCodeWidth,
      height: codeBlockHeight,
      languagePainter: languagePainter,
      codePainter: codePainter,
    );
  }

// 创建错误布局
  static MessageLayout createErrorLayout(double maxBubbleWidth, double bubblePadding) {
    final errorPainter = TextPainter(
      text: const TextSpan(
        text: '消息渲染失败',
        style: TextStyle(color: Colors.red, fontSize: 15),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxBubbleWidth - bubblePadding * 2);

    return MessageLayout(
      contentBlocks: [ContentBlock.text(errorPainter)],
      totalHeight: 40.0,
      bubbleWidth: 120.0,
    );
  }
}

class MarkdownTextProcessor {
  static final RegExp headerPattern = RegExp(r'^(#{1,6})\s(.+)$', multiLine: true);
  static final RegExp emphasisPattern = RegExp(r'\*([^*]+)\*');
  static final RegExp strongPattern = RegExp(r'\*\*([^*]+)\*\*');
  static final RegExp strikethroughPattern = RegExp(r'~~([^~]+)~~');
  static final RegExp linkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

  static TextStyle getHeaderStyle(int level, TextStyle baseStyle) {
    double fontSize = 22 - ((level - 1) * 2); // h1: 22, h2: 20, h3: 18, etc.
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  static List<TextSpan> processMarkdownText(
    String text,
    TextStyle baseStyle,
    Color linkColor,
  ) {
    List<TextSpan> spans = [];
    List<String> lines = text.split('\n');

    for (String line in lines) {
      // Process headers
      var headerMatch = headerPattern.firstMatch(line);
      if (headerMatch != null) {
        int headerLevel = headerMatch.group(1)!.length;
        String headerText = headerMatch.group(2)!;
        spans.add(TextSpan(
          text: '$headerText\n',
          style: getHeaderStyle(headerLevel, baseStyle),
        ));
        continue;
      }

      // Process inline formatting
      String currentLine = line;
      int lastIndex = 0;
      List<TextSpan> lineSpans = [];

      // Process strong (bold) text
      var strongMatches = strongPattern.allMatches(currentLine);
      for (var match in strongMatches) {
        if (match.start > lastIndex) {
          lineSpans.add(TextSpan(
            text: currentLine.substring(lastIndex, match.start),
            style: baseStyle,
          ));
        }
        lineSpans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        lastIndex = match.end;
      }

      // Process emphasis (italic) text
      if (lastIndex < currentLine.length) {
        String remainingText = currentLine.substring(lastIndex);
        var emphasisMatches = emphasisPattern.allMatches(remainingText);
        lastIndex = 0;

        for (var match in emphasisMatches) {
          if (match.start > lastIndex) {
            lineSpans.add(TextSpan(
              text: remainingText.substring(lastIndex, match.start),
              style: baseStyle,
            ));
          }
          lineSpans.add(TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          lastIndex = match.end;
        }
      }

      // Add any remaining text
      if (lastIndex < currentLine.length) {
        lineSpans.add(TextSpan(
          text: currentLine.substring(lastIndex),
          style: baseStyle,
        ));
      }

      // Add newline for each line except the last one
      lineSpans.add(const TextSpan(text: '\n'));
      spans.addAll(lineSpans);
    }

    return spans;
  }
}

// 表格数据结构
class MarkdownTable {
  final List<List<String>> headers;
  final List<List<String>> rows;
  final List<double> columnWidths;
  final double totalWidth;
  final double totalHeight;
  final double rowHeight;
  final double headerHeight;

  MarkdownTable({
    required this.headers,
    required this.rows,
    required this.columnWidths,
    required this.totalWidth,
    required this.totalHeight,
    required this.rowHeight,
    required this.headerHeight,
  });
}

class TableCell {
  final String content;
  final TextPainter textPainter;
  final double width;
  final double height;

  TableCell({
    required this.content,
    required this.textPainter,
    required this.width,
    required this.height,
  });
}

class MarkdownTableProcessor {
  static final RegExp tablePattern = RegExp(
    r'\|(.*)\|\s*\n\|([-\s|:]*)\|\s*\n((?:\|.*\|\s*\n?)*)',
    multiLine: true,
  );

  static List<String> _parseCells(String row) {
    // 移除首尾的 | 符号后拆分单元格
    final cells = row.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|');
    // 清理每个单元格的空白
    return cells.map((cell) => cell.trim()).toList();
  }

  static Future<MarkdownTable?> processTable(
    String text,
    double maxWidth,
    TextStyle baseStyle,
    TextStyle headerStyle,
  ) async {
    try {
      final tableMatch = tablePattern.firstMatch(text);
      if (tableMatch == null) return null;
      // 解析表头
      final headerRow = tableMatch.group(1)!;
      final bodyRows = tableMatch.group(3)!;
      // 处理表头，获取实际的列名
      final headers = _parseCells(headerRow);
      // 处理表格行
      final rows = bodyRows
          .split('\n')
          .where((row) => row.trim().isNotEmpty)
          .map((row) => _parseCells(row))
          .where((row) => row.isNotEmpty) // 过滤空行
          .toList();

      if (headers.isEmpty || rows.isEmpty) return null;

      // 使用实际的列数
      final columnCount = headers.length;

      // 规范化所有行的列数，确保与表头列数相同
      List<List<String>> normalizedRows = rows.map((row) {
        if (row.length < columnCount) {
          return [...row, ...List.filled(columnCount - row.length, '')];
        }
        return row.sublist(0, columnCount);
      }).toList();

      // 计算列宽时确保总宽度精确等于 maxWidth
      const cellPadding = 16.0;
      final availableWidth = maxWidth;
      final columnWidth = availableWidth / columnCount;
      List<double> columnWidths = List.filled(columnCount, columnWidth);

      // 处理可能的舍入误差，确保总宽度精确等于 maxWidth
      double actualTotalWidth = columnWidths.reduce((a, b) => a + b);
      if (actualTotalWidth != maxWidth) {
        // 将差值添加到最后一列
        columnWidths[columnWidths.length - 1] += maxWidth - actualTotalWidth;
      }

      // 计算行高
      double maxHeaderHeight = 0.0;
      for (final header in headers) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: header,
            style: headerStyle,
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        maxHeaderHeight = max(maxHeaderHeight, textPainter.height);
      }

      double maxRowHeight = 0.0;
      for (final row in normalizedRows) {
        double rowHeight = 0.0;
        for (final cell in row) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: cell,
              style: baseStyle,
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          rowHeight = max(rowHeight, textPainter.height);
        }
        maxRowHeight = max(maxRowHeight, rowHeight);
      }

      final headerHeight = maxHeaderHeight + cellPadding * 2;
      final rowHeight = maxRowHeight + cellPadding * 2;
      final totalHeight = headerHeight + (rowHeight * normalizedRows.length);

      return MarkdownTable(
        headers: [headers],
        rows: normalizedRows,
        columnWidths: columnWidths,
        totalWidth: maxWidth,
        totalHeight: totalHeight,
        rowHeight: rowHeight,
        headerHeight: headerHeight,
      );
    } catch (e, stackTrace) {
      commonPrint('Error processing table: $e');
      commonPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}

// 内容匹配类
class ContentMatch {
  final ContentMatchType type;
  final int start;
  final int end;
  final RegExpMatch match;

  ContentMatch({
    required this.type,
    required this.start,
    required this.end,
    required this.match,
  });
}

class CodeBlockLayout {
  final String language;
  final String code;
  final double width;
  final double height;
  final TextPainter languagePainter;
  final TextPainter codePainter;

  CodeBlockLayout({
    required this.language,
    required this.code,
    required this.width,
    required this.height,
    required this.languagePainter,
    required this.codePainter,
  });
}

// 定义内容块类
class ContentBlock {
  final ContentBlockType type;
  final TextPainter? textPainter;
  final CodeBlockLayout? codeBlock;
  final ui.Image? image;
  final double? imageWidth;
  final double? imageHeight;
  final double height;
  final MarkdownTable? table;
  final PaintingStyle? borderStyle;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? headerBackgroundColor;

  ContentBlock.text(TextPainter painter)
      : type = ContentBlockType.text,
        textPainter = painter,
        codeBlock = null,
        image = null,
        imageWidth = null,
        imageHeight = null,
        height = painter.height,
        table = null,
        borderStyle = null,
        borderColor = null,
        backgroundColor = null,
        headerBackgroundColor = null;

  ContentBlock.code(CodeBlockLayout block)
      : type = ContentBlockType.code,
        textPainter = null,
        codeBlock = block,
        image = null,
        imageWidth = null,
        imageHeight = null,
        height = block.height,
        table = null,
        borderStyle = null,
        borderColor = null,
        backgroundColor = null,
        headerBackgroundColor = null;

  ContentBlock.image(ui.Image img, double width, this.height)
      : type = ContentBlockType.image,
        textPainter = null,
        codeBlock = null,
        image = img,
        imageWidth = width,
        imageHeight = height,
        table = null,
        borderStyle = null,
        borderColor = null,
        backgroundColor = null,
        headerBackgroundColor = null;

  ContentBlock.table(
    MarkdownTable tableData,
    PaintingStyle style,
    Color border,
    Color background,
    Color headerBackground,
  )   : type = ContentBlockType.table,
        textPainter = null,
        codeBlock = null,
        image = null,
        imageWidth = null,
        imageHeight = null,
        height = tableData.totalHeight,
        table = tableData,
        borderStyle = style,
        borderColor = border,
        backgroundColor = background,
        headerBackgroundColor = headerBackground;
}

// 修改 MessageLayout 类
class MessageLayout {
  final List<ContentBlock> contentBlocks;
  final double totalHeight;
  final double bubbleWidth;

  MessageLayout({
    required this.contentBlocks,
    required this.totalHeight,
    required this.bubbleWidth,
  });
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: BoxFit.contain,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}