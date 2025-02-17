import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/utils/common_methods.dart';
import '../config/change_settings.dart';

class WindowButton extends StatefulWidget {
  final String tooltip;
  final String iconPath;
  final VoidCallback onTap;
  final bool isMaximizeButton;
  final bool isCloseButton;

  const WindowButton(
      {super.key, required this.tooltip, required this.iconPath, required this.onTap, this.isMaximizeButton = false, this.isCloseButton = false});

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  Widget _buildWindowButton({
    required String tooltip,
    required String iconPath,
    required VoidCallback onTap,
    required ChangeSettings settings,
    bool isCloseButton = false,
  }) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Tooltip(
          message: '',
          child: MouseRegion(
            onEnter: (_) {
              setState(() => isHovered = true);
            },
            onExit: (_) {
              setState(() => isHovered = false);
            },
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  color: isHovered
                      ? isCloseButton
                          ? Colors.red
                          : getRealDarkMode(settings)
                              ? Colors.white.withAlpha(25)
                              : Colors.black.withAlpha(25)
                      : Colors.transparent,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                      (isHovered && isCloseButton) ? Colors.white : settings.getAppbarTextColor(),
                      BlendMode.srcIn,
                    ),
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return _buildWindowButton(
        tooltip: widget.tooltip, iconPath: widget.iconPath, onTap: widget.onTap, settings: settings, isCloseButton: widget.isCloseButton);
  }
}
