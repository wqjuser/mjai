import 'package:flutter/material.dart';

class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const AutoScrollText({
    Key? key,
    required this.text,
    required this.textStyle,
  }) : super(key: key);

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _contentWidth = 0;
  double _containerWidth = 0;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback(_checkIfNeedsScroll);
  }

  void _checkIfNeedsScroll(_) {
    if (!mounted) return;

    // 计算容器宽度
    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
    if (containerBox != null) {
      _containerWidth = containerBox.size.width;
    }

    // 计算文本宽度
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    _contentWidth = textPainter.width;

    setState(() {
      _needsScroll = _contentWidth > _containerWidth - 30;
    });

    if (_needsScroll) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final offset = _needsScroll
            ? (_controller.value * (_contentWidth + 50)) % (_contentWidth + 50)
            : 0.0;

        return SizedBox(
          width: constraints.maxWidth,
          height: 48,
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Transform.translate(
                offset: Offset(-offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 添加这行
                  children: [
                    const Text(
                      '📢 ',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (_needsScroll) ...[
                      Text(
                        widget.text,
                        style: widget.textStyle,
                        maxLines: 1,
                      ),
                      const SizedBox(width: 50),
                      Text(
                        widget.text,
                        style: widget.textStyle,
                        maxLines: 1,
                      ),
                    ] else
                      Text(
                        widget.text,
                        style: widget.textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback(_checkIfNeedsScroll);
    }
  }
}
