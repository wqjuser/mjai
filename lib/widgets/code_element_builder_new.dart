import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:universal_code_viewer/universal_code_viewer.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  final ChangeSettings settings;

  CodeElementBuilder(this.settings);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code') {
      final String codeText = element.textContent;
      final String? language = element.attributes['class'];
      bool isCodeBlock = codeText.contains('\n') || language != null;
      if (isCodeBlock) {
        // 代码块渲染
        return CodeViewWidget(codeContent: codeText, codeLanguage: language ?? '-代码语言未知', settings: settings);
      } else {
        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: codeText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: settings.getTextColor(),
                ),
              ),
            ],
          ),
        );
      }
    }
    return null;
  }
}

class CodeViewWidget extends StatefulWidget {
  final String codeContent;
  final String codeLanguage;
  final ChangeSettings settings;

  const CodeViewWidget({super.key, required this.codeContent, required this.codeLanguage, required this.settings});

  @override
  State<CodeViewWidget> createState() => _CodeViewWidgetState();
}

class _CodeViewWidgetState extends State<CodeViewWidget> {
  late Widget _copyIcon;
  late Widget _runIcon;
  bool hasCopied = false;
  bool hasRun = false;
  bool isExpanded = false;
  bool isHovering = false;
  Timer? _hoverTimer;
  double _buttonTop = 5;
  final bool isPC = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  final GlobalKey _codeBlockKey = GlobalKey();

  @override
  void initState() {
    _copyIcon = Icon(Icons.copy_rounded, color: Colors.black, key: const ValueKey('copy'), size: isPC ? 20 : 16);
    _runIcon = Icon(Icons.play_arrow_rounded, color: Colors.black, key: const ValueKey('play'), size: isPC ? 20 : 16);
    super.initState();
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  String getLast20Lines(String text) {
    // 使用换行符分割文本成行
    List<String> lines = text.split('\n');

    // 计算文本中的行数
    int totalLines = lines.length;

    // 获取最后 20 行
    // 如果文本行数少于 20，则返回所有行
    List<String> last20Lines = lines.sublist(totalLines > 20 ? totalLines - 20 : 0);

    // 使用换行符重新组合成一个字符串
    return last20Lines.join('\n');
  }

  void runVisibleCommand(String command) async {
    ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run('cmd.exe', ['/c', 'start', 'cmd', '/k', '$command && exit']);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', ['-a', 'Terminal', '--args', 'sh', '-c', '$command && exit']);
    } else {
      commonPrint('不支持此操作系统。');
      return;
    }
    if (result.exitCode == 0) {
      commonPrint('命令运行成功。');
    } else {
      commonPrint('命令运行失败: ${result.stderr}');
    }
  }

  Widget buildExpandSection(int totalLines, ChangeSettings settings) {
    if (!isExpanded && totalLines > 20) {
      return Container(
        width: double.infinity, // 确保容器占据全宽
        color: getRealDarkMode(settings) ? Colors.black : Colors.white,
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '共 $totalLines 行代码',
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: () => setState(() => isExpanded = true),
              child: const Text(
                '显示全部',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget buildFloatingButtons() {
    final codeLines = widget.codeContent.trimRight().split('\n');
    final bool isPC = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (codeLines.length > 20)
              Tooltip(
                  message: isExpanded ? '收起' : '展开',
                  child: Padding(
                    padding: EdgeInsets.all(isPC ? 8 : 4),
                    child: InkWell(
                      onTap: () =>
                          setState(() {
                            isExpanded = !isExpanded;
                            if (!isExpanded) _buttonTop = 5;
                          }),
                      child: Icon(isExpanded ? Icons.close : Icons.expand_more, color: Colors.black, size: isPC ? 20 : 16),
                    ),
                  )),
            Tooltip(
                message: '复制',
                child: Padding(
                  padding: EdgeInsets.all(isPC ? 8 : 4),
                  child: InkWell(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _copyIcon,
                    ),
                    onTap: () async {
                      if (hasCopied) return;
                      await Clipboard.setData(ClipboardData(text: widget.codeContent));
                      setState(() {
                        _copyIcon = Icon(Icons.check, color: Colors.black, key: const ValueKey('check'), size: isPC ? 20 : 16);
                        hasCopied = true;
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _copyIcon =
                                Icon(Icons.copy_rounded, color: Colors.black, key: const ValueKey('copy'), size: isPC ? 20 : 16);
                            hasCopied = false;
                          });
                        }
                      });
                    },
                  ),
                )),
            if (isPC && (widget.codeLanguage
                .split('-')
                .last == 'bash' || widget.codeLanguage
                .split('-')
                .last == 'shell'))
              Tooltip(
                message: '运行',
                child: Padding(
                  padding: EdgeInsets.all(isPC ? 8 : 4),
                  child: InkWell(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _runIcon,
                    ),
                    onTap: () {
                      if (hasRun) return;
                      runVisibleCommand(widget.codeContent.trimRight());
                      setState(() {
                        _runIcon = const Icon(Icons.check, color: Colors.black, key: ValueKey('check'), size: 26);
                        hasRun = true;
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _runIcon = const Icon(Icons.play_arrow_rounded, color: Colors.black, key: ValueKey('play'), size: 26);
                            hasRun = false;
                          });
                        }
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codeLines = widget.codeContent.trimRight().split('\n');
    final totalLines = codeLines.length;
    final bool isPC = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return MouseRegion(
        onEnter: (_) {
          _hoverTimer?.cancel();
          setState(() => isHovering = true);
        },
        onHover: (event) {
          if (isExpanded) {
            final RenderBox renderBox = _codeBlockKey.currentContext?.findRenderObject() as RenderBox;
            final Size size = renderBox.size;
            if (event.localPosition.dy >= 0 && event.localPosition.dy - 45 <= size.height - 50) {
              setState(() => _buttonTop = event.localPosition.dy - 45);
            }
          }
        },
        onExit: (_) {
          _hoverTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => isHovering = false);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: getRealDarkMode(widget.settings) ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // 确保子组件填充整个宽度
                children: [
                  Container(
                    key: _codeBlockKey,
                    child: UniversalCodeViewer(
                      code: isExpanded ? widget.codeContent.trimRight() : getLast20Lines(widget.codeContent.trimRight()),
                      style: getRealDarkMode(widget.settings) ? SyntaxHighlighterStyles.githubDark : SyntaxHighlighterStyles.githubLight,
                      codeLanguage: widget.codeLanguage
                          .split('-')
                          .last,
                      showLineNumbers: false,
                      enableCopy: false,
                      isCodeLanguageView: true,
                    ),
                  ),
                  buildExpandSection(totalLines, widget.settings),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                top: _buttonTop,
                right: 8,
                child: MouseRegion(
                  onEnter: (_) => setState(() => isHovering = true),
                  onExit: (_) => setState(() => isHovering = false),
                  child: AnimatedOpacity(
                    opacity: (isHovering || !isPC) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: buildFloatingButtons(),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
