import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../config/change_settings.dart';

class CustomThinkElementBuilder extends MarkdownElementBuilder {
  final ChangeSettings settings;
  final bool isThink;

  CustomThinkElementBuilder(this.settings, this.isThink);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // 保持原始的 Markdown 格式，包括标记符号
    var content = element.children
        ?.map((child) {
          if (child is md.Text) {
            return child.text;
          } else if (child is md.Element) {
            // 处理不同类型的 Markdown 元素
            switch (child.tag) {
              case 'p':
                return '${_processInlineElements(child)}\n\n';
              case 'strong':
                return '**${child.textContent}**';
              case 'em':
                return '_${child.textContent}_';
              case 'br':
                return '\n';
              default:
                return _processInlineElements(child);
            }
          }
          return '';
        })
        .join('')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return ExpandableThink(
      content: content ?? '',
      settings: settings,
      isThink: isThink,
    );
  }

  // 处理内联元素，保持格式
  String _processInlineElements(md.Element element) {
    return element.children?.map((child) {
          if (child is md.Text) {
            return child.text;
          } else if (child is md.Element) {
            switch (child.tag) {
              case 'strong':
                return '**${child.textContent}**';
              case 'em':
                return '_${child.textContent}_';
              default:
                return child.textContent;
            }
          }
          return '';
        }).join('') ??
        '';
  }
}

class ExpandableThink extends StatefulWidget {
  final String content;
  final ChangeSettings settings;
  final bool isThink;

  const ExpandableThink({
    Key? key,
    required this.isThink,
    required this.content,
    required this.settings,
  }) : super(key: key);

  @override
  State<ExpandableThink> createState() => _ExpandableThinkState();
}

class _ExpandableThinkState extends State<ExpandableThink> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onDoubleTap: () {
          setState(() {
            if (widget.isThink) {
              isExpanded = !isExpanded;
            }
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            if (widget.isThink) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.settings.effectiveDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(4),
                      topRight: const Radius.circular(4),
                      // 当收起时，底部也需要圆角
                      bottomLeft: Radius.circular(isExpanded ? 0 : 4),
                      bottomRight: Radius.circular(isExpanded ? 0 : 4),
                    ),
                    // 当收起时，添加左侧绿色边框
                    border: !isExpanded
                        ? const Border(
                            left: BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: widget.settings.getTextColor(),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '思考过程:',
                        style: TextStyle(
                          color: widget.settings.getTextColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
            // 内容区域
            AnimatedCrossFade(
              firstChild: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.settings.effectiveDarkMode ? Colors.grey[800] : Colors.grey[200],
                  border: const Border(
                    left: BorderSide(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 6),
                child: MarkdownBody(
                  data: widget.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: widget.settings.getTextColor(),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    h1: const TextStyle(height: 1.5),
                    h2: const TextStyle(height: 1.5),
                    h3: const TextStyle(height: 1.5),
                    h4: const TextStyle(height: 1.5),
                    h5: const TextStyle(height: 1.5),
                    h6: const TextStyle(height: 1.5),
                    blockSpacing: 12.0,
                    listIndent: 24.0,
                    blockquotePadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  ),
                  softLineBreak: true,
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
