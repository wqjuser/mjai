import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';

class CodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String text;
  final String? language;

  const CodeWrapperWidget({Key? key, required this.child, required this.text, this.language = ''}) : super(key: key);

  @override
  State<CodeWrapperWidget> createState() => _CodeWrapperState();
}

class _CodeWrapperState extends State<CodeWrapperWidget> {
  late Widget _copyIcon;
  late Widget _runIcon;
  bool hasCopied = false;
  bool hasRun = false;
  bool isExpanded = false;
  bool isHovering = false;
  Timer? _hoverTimer;
  double _buttonTop = 5;
  final GlobalKey _codeBlockKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _copyIcon = const Icon(Icons.copy_rounded, key: ValueKey('copy'), size: 20);
    _runIcon = const Icon(Icons.play_arrow_rounded, key: ValueKey('play'), size: 26);
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
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
      if (mounted) {
        if (Platform.isWindows) {
          showHint('非windows命令，无法执行');
        } else {
          showHint('非macOS命令，无法执行');
        }
      }
    }
  }

  Widget buildCodeView({ChangeSettings? settings}) {
    final codeLines = widget.text.trimRight().split('\n');
    final totalLines = codeLines.length;

    // 当代码行数超过20行且未展开时，显示最后20行，否则显示全部
    final displayedLines = isExpanded
        ? codeLines
        : (totalLines > 20
            ? codeLines.skip(totalLines - 20).toList() // 显示最后20行
            : codeLines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayedLines.map((line) => Text(line)),
        if (!isExpanded && totalLines > 20)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('共 $totalLines 行'),
                TextButton(
                  onPressed: () => setState(() => isExpanded = true),
                  child: Text('显示全部', style: TextStyle(color: settings!.getSelectedBgColor())),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildFloatingButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
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
          IconButton(
            icon: Icon(isExpanded ? Icons.close : Icons.expand_more),
            onPressed: () => setState(() {
              isExpanded = !isExpanded;
              if (!isExpanded) _buttonTop = 5;
            }),
            tooltip: isExpanded ? '收起' : '展开',
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _copyIcon,
            ),
            onPressed: () async {
              if (hasCopied) return;
              await Clipboard.setData(ClipboardData(text: widget.text));
              setState(() {
                _copyIcon = const Icon(Icons.check, key: ValueKey('check'), size: 20);
                hasCopied = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _copyIcon = const Icon(Icons.copy_rounded, key: ValueKey('copy'), size: 20);
                    hasCopied = false;
                  });
                }
              });
            },
            tooltip: '复制',
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _runIcon,
            ),
            onPressed: () {
              if (hasRun) return;
              runVisibleCommand(widget.text.trimRight());
              setState(() {
                _runIcon = const Icon(Icons.check, key: ValueKey('check'), size: 26);
                hasRun = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _runIcon = const Icon(Icons.play_arrow_rounded, key: ValueKey('play'), size: 26);
                    hasRun = false;
                  });
                }
              });
            },
            tooltip: '运行',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) {
            _hoverTimer?.cancel();
            setState(() => isHovering = true);
          },
          onHover: (event) {
            if (isExpanded) {
              final RenderBox renderBox = _codeBlockKey.currentContext?.findRenderObject() as RenderBox;
              final Size size = renderBox.size;
              if (event.localPosition.dy >= 0 && event.localPosition.dy - 15 <= size.height - 50) {
                setState(() => _buttonTop = event.localPosition.dy - 15);
              }
            }
          },
          onExit: (_) {
            _hoverTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => isHovering = false);
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: _codeBlockKey,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: IntrinsicWidth(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: buildCodeView(settings: settings),
                      ),
                    ),
                  ),
                ),
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
                    opacity: isHovering ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: buildFloatingButtons(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
