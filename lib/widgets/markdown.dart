import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/widgets/code_element_builder_new.dart';
import 'package:tuitu/widgets/image_preview_widget.dart';
import 'package:tuitu/widgets/math_element_builder.dart';
import 'package:tuitu/widgets/video_element_builder.dart';
import '../config/change_settings.dart';
import '../utils/common_methods.dart';
import 'custom_think_builder.dart';
import 'my_latex_inline_syntax.dart';
import 'package:markdown/markdown.dart' as md;

class MyMarkdown extends StatelessWidget {
  final String text;

  final bool isSendByMe;
  final bool isThinkModel;

  const MyMarkdown({
    super.key,
    required this.text,
    this.isSendByMe = true,
    this.isThinkModel = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          MarkdownBody(
            data: text,
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet(
              // 设置表格内容的文字颜色
              tableBody: TextStyle(color: settings.getTextColor()),
              // 设置表头的文字颜色
              tableHead: TextStyle(color: settings.getTextColor()),
              // 设置所有文本样式
              p: TextStyle(
                fontSize: 16,
                color: settings.getTextColor(),
              ),
              // 设置标题样式
              h1: TextStyle(
                color: settings.getTextColor(),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                color: settings.getTextColor(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                color: settings.getTextColor(),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              h4: TextStyle(
                color: settings.getTextColor(),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              h5: TextStyle(
                color: settings.getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              h6: TextStyle(
                color: settings.getTextColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              // 设置链接样式
              a: const TextStyle(
                color: Colors.blue,
              ),
              // 设置强调文本样式
              em: TextStyle(
                fontSize: 14,
                color: settings.getTextColor(),
                fontStyle: FontStyle.italic,
              ),
              // 设置加粗文本样式
              strong: TextStyle(
                color: settings.getTextColor(),
                fontWeight: FontWeight.bold,
              ),
              // 设置删除线文本样式
              del: TextStyle(
                color: settings.getTextColor().withAlpha(178),
                decoration: TextDecoration.lineThrough,
              ),
              codeblockPadding: EdgeInsets.zero,
              // 移除代码块的默认内边距
              codeblockDecoration: BoxDecoration(
                // 修改代码块的背景装饰
                color: Colors.transparent, // 使背景透明
                borderRadius: BorderRadius.circular(8),
              ),
              // 设置引用样式
              blockquote: TextStyle(
                color: settings.getTextColor(),
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                color: settings.effectiveDarkMode ? Colors.grey[800] : Colors.blue[200], // 引用块的背景色
                borderRadius: BorderRadius.circular(8),
              ),
              // 设置列表样式
              listBullet: TextStyle(
                color: settings.getTextColor(),
              ),
              // 设置分割线样式
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: settings.getSelectedBgColor().withAlpha(153), // 分割线颜色
                    width: 1.0, // 分割线宽度
                    style: BorderStyle.solid, // 分割线样式（可改为 BorderStyle.dashed）
                  ),
                ),
              ),
            ),
            builders: {
              'code': CodeElementBuilder(settings),
              'latex': MathElementBuilder(isSendByMe: isSendByMe, settings: settings),
              'video': VideoElementBuilder(settings),
              'blockquote': CustomThinkElementBuilder(settings, isThinkModel),
              // 'tk': CustomThinkElementBuilder(settings, true),
            },
            inlineSyntaxes: [MyLatexInlineSyntax()],
            onTapLink: (text, href, title) {
              myLaunchUrl(Uri.parse(href ?? ''));
            },
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubWeb.blockSyntaxes,
              [
                ...md.ExtensionSet.gitHubWeb.inlineSyntaxes,
                VideoSyntax(), // 视频语法解析器
              ],
            ),
            imageBuilder: (uri, title, alt) {
              return ImagePreviewWidget(
                imageUrl: uri.toString(),
                previewHeight: 200,
                previewWidth: 200,
              );
            },
          )
        ]),
      ),
    );
  }
}

class VideoSyntax extends md.InlineSyntax {
  VideoSyntax() : super(r'!video\[(.*?)\]\((.*?)\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element('video', [])
      ..attributes['src'] = match.group(2) ?? ''
      ..attributes['cover'] = match.group(1) ?? '';
    parser.addNode(element);
    return true;
  }
}

/// 自定义语法解析器，用于匹配 !think  结构
class ThinkSyntax extends md.InlineSyntax {
  ThinkSyntax() : super(r'tk (.*)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final thinkContent = match.group(1); // 提取内容
    parser.addNode(md.Element('tk', [md.Text(thinkContent!)]));
    return true;
  }
}
