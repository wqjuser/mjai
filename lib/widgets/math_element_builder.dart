import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tuitu/config/change_settings.dart';

import '../utils/common_methods.dart';

class MathElementBuilder extends MarkdownElementBuilder {
  final bool isSendByMe;
  final ChangeSettings settings;

  MathElementBuilder({required this.isSendByMe, required this.settings});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (!isSendByMe) {
      final String content = element.textContent;

      try {
        if (content.startsWith(r'$$') && content.endsWith(r'$$')) {
          // 块级公式
          final String math = content.substring(2, content.length - 2).trim();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: content));
                  showHint('复制成功', showType: 4, showPosition: 3, showTime: 500);
                },
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Math.tex(
                          math,
                          textStyle: preferredStyle ?? const TextStyle(fontSize: 16),
                          options: MathOptions(
                            style: MathStyle.display,
                            color: settings.getTextColor(),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )),
          );
        } else if (content.startsWith(r'$') && content.endsWith(r'$')) {
          // 行内公式
          final String math = content.substring(1, content.length - 1).trim();
          return SelectableText.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: content));
                        showHint('复制成功', showType: 4, showPosition: 3, showTime: 500);
                      },
                      child: Math.tex(
                        math,
                        textStyle: preferredStyle ?? const TextStyle(fontSize: 16),
                        options: MathOptions(
                          style: MathStyle.text,
                          color: settings.getTextColor(),
                          fontSize: 16,
                        ),
                      )),
                ),
              ],
            ),
          );
        }
      } catch (e, stackTrace) {
        commonPrint('数学公式渲染错误: $e');
        commonPrint('错误堆栈: $stackTrace');
        return SelectableText(
          content,
          style: TextStyle(
            color: Colors.red,
            fontSize: preferredStyle?.fontSize ?? 16,
          ),
        );
      }
    }
    return null;
  }
}
