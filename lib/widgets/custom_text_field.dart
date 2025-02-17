import 'dart:ui';
import 'package:flutter/material.dart';
class CustomTextField extends TextField {
  final Widget? rightView;
  final VoidCallback? onRightViewTap;
  final Size? rightViewSize;

  CustomTextField({
    super.key,
    super.controller,
    super.focusNode,
    InputDecoration? decoration,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization = TextCapitalization.none,
    super.style,
    super.strutStyle,
    super.textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    super.textDirection,
    super.readOnly = false,
    super.showCursor,
    super.autofocus = false,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.autocorrect = true,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions = true,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.maxLength,
    super.maxLengthEnforcement,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.selectionHeightStyle = BoxHeightStyle.tight,
    super.selectionWidthStyle = BoxWidthStyle.tight,
    super.keyboardAppearance,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.enableInteractiveSelection = true,
    super.selectionControls,
    super.onTap,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints = const <String>[],
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scribbleEnabled = true,
    super.enableIMEPersonalizedLearning = true,
    this.rightView,
    this.onRightViewTap,
    this.rightViewSize,
  }) : super(
    decoration: (decoration ?? const InputDecoration()).copyWith(
      suffix: rightView != null
          ? _CustomSuffix(
        onTap: onRightViewTap,
        size: rightViewSize,
        child: rightView,
      )
          : null,
      isCollapsed: false,
    ),
    textAlignVertical: textAlignVertical ?? TextAlignVertical.center,
  );
}

class _CustomSuffix extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Size? size;

  const _CustomSuffix({
    Key? key,
    required this.child,
    this.onTap,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: size?.width,
        height: size?.height,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 2), // 微调以对齐基线
        child: child,
      ),
    );
  }
}