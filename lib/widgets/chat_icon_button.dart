import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ChatIconButton extends StatefulWidget {
  final String iconPath;
  final VoidCallback onTap;
  final String hoverText;
  final bool isEnabled;
  final bool alwaysShowText;
  final Color color;

  const ChatIconButton({
    Key? key,
    required this.iconPath,
    required this.onTap,
    required this.hoverText,
    this.isEnabled = true,
    this.alwaysShowText = false,
    required this.color,
  }) : super(key: key);

  @override
  State<ChatIconButton> createState() => _ChatIconButtonState();
}

class _ChatIconButtonState extends State<ChatIconButton> {
  bool isHovering = false;
  bool shouldShowText = false;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _startHoverTimer() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && isHovering) {
        setState(() {
          shouldShowText = true;
        });
      }
    });
  }

  void _resetHoverState() {
    _hoverTimer?.cancel();
    if (mounted) {
      setState(() {
        isHovering = false;
        shouldShowText = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕方向
    Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (event) {
            setState(() {
              isHovering = true;
            });
            _startHoverTimer();
          },
          onExit: (event) => _resetHoverState(),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isEnabled ? widget.color : Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3, right: 6),
              child: Row(
                children: [
                  SvgPicture.asset(
                    widget.iconPath,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      widget.isEnabled ? widget.color : Colors.grey,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'tip',
                  ),
                  if (shouldShowText || widget.alwaysShowText) ...[
                    if (orientation == Orientation.landscape || Platform.isWindows || Platform.isWindows) ...[
                      Center(
                        child: Text(
                          ' ${widget.hoverText}',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isEnabled ? widget.color : Colors.grey,
                          ),
                        ),
                      ),
                    ]
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
