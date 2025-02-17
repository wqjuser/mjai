import 'dart:io';

import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

class CustomDialog extends StatefulWidget {
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final String? title;
  final String? description;
  final String? warn;
  final Widget? content;
  final Function()? onConfirm;
  final Function()? onCancel;
  final bool showConfirmButton;
  final bool showCancelButton;
  final bool useScrollContent;
  final String confirmButtonText;
  final String cancelButtonText;
  final DecorationImage? backgroundImage;
  final double backgroundOpacity;
  final double blurRadius;
  final Color contentBackgroundColor;
  final Color? backgroundColor;
  final double contentBackgroundOpacity;
  final Color? titleColor;
  final Color? descColor;
  final Color? warnColor;
  final Color? cancelButtonColor;
  final Color? conformButtonColor;
  final bool isConformClose;
  final bool isCancelClose;
  final bool useSysClose;
  final Axis scrollDirection;
  final bool singleLineTitle;

  const CustomDialog(
      {super.key,
      this.minWidth = 100.0, // 默认最小宽度
      this.minHeight = 100.0, // 默认最小高度
      this.maxWidth = 300.0,
      this.maxHeight = double.infinity,
      this.title,
      this.description,
      this.warn,
      this.content,
      this.onConfirm,
      this.onCancel,
      this.showConfirmButton = true,
      this.showCancelButton = true,
      this.useScrollContent = true,
      this.confirmButtonText = 'Confirm',
      this.cancelButtonText = 'Cancel',
      this.backgroundImage,
      this.backgroundOpacity = 1.0,
      this.scrollDirection = Axis.vertical,
      this.blurRadius = 10.0,
      this.titleColor = Colors.black,
      this.warnColor = Colors.yellowAccent,
      this.backgroundColor,
      this.contentBackgroundColor = Colors.white,
      this.descColor = Colors.white,
      this.cancelButtonColor = Colors.grey,
      this.conformButtonColor = Colors.blue,
      this.isConformClose = true,
      this.useSysClose = true,
      this.isCancelClose = true,
      this.contentBackgroundOpacity = 1.0,
      this.singleLineTitle = false});

  @override
  State<StatefulWidget> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 24), // 自定义水平边距
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
            decoration: BoxDecoration(color: settings.getBackgroundColor(), borderRadius: BorderRadius.circular(10.0)),
            constraints: BoxConstraints(
              minWidth: widget.minWidth,
              minHeight: widget.minHeight,
              maxWidth: widget.maxWidth,
              maxHeight: widget.maxHeight,
            ),
            padding: const EdgeInsets.all(10.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          color: widget.contentBackgroundColor.withAlpha((widget.contentBackgroundOpacity * 255).toInt()),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(widget.title!,
                                    maxLines: widget.singleLineTitle == true ? 1 : null,
                                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: widget.titleColor)),
                              ),
                            if (widget.description != null) const SizedBox(height: 10.0),
                            if (widget.description != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                child: EasyRichText(
                                  '${widget.description}${widget.warn ?? ''}',
                                  defaultStyle: TextStyle(color: widget.descColor!),
                                  patternList: [
                                    if (widget.warn != null)
                                      EasyRichTextPattern(
                                        targetString: widget.warn ?? '',
                                        style: TextStyle(color: widget.warnColor),
                                      ),
                                  ],
                                ),
                              ),
                            if (widget.content != null)
                              widget.useScrollContent
                                  ? ConstrainedBox(
                                      constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
                                      // adjust the value as needed
                                      child: SingleChildScrollView(
                                        scrollDirection: widget.scrollDirection,
                                        child: widget.content!,
                                      ))
                                  : ConstrainedBox(
                                      constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
                                      // adjust the value as needed
                                      child: widget.content!,
                                    ),
                            if ((widget.showCancelButton && widget.onCancel != null) ||
                                (widget.showConfirmButton && widget.onConfirm != null))
                              Padding(
                                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10.0),
                                      Row(
                                        children: <Widget>[
                                          if (widget.showCancelButton && widget.onCancel != null)
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  if (widget.isCancelClose) {
                                                    Navigator.of(context).pop();
                                                  }
                                                  if (widget.onCancel != null) widget.onCancel!();
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all<Color>(widget.cancelButtonColor ?? Colors.grey),
                                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                  ),
                                                ),
                                                child: Text(widget.cancelButtonText, style: const TextStyle(color: Colors.white)),
                                              ),
                                            ),
                                          const SizedBox(width: 10),
                                          if (widget.showConfirmButton && widget.onConfirm != null)
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  if (widget.isConformClose) {
                                                    Navigator.of(context).pop();
                                                  }
                                                  if (widget.onConfirm != null) widget.onConfirm!();
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all<Color>(widget.conformButtonColor ?? Colors.blue),
                                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                  ),
                                                ),
                                                child:
                                                    Text(widget.confirmButtonText, style: const TextStyle(color: Colors.white)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10.0),
                                    ],
                                  )),
                          ],
                        ))
                  ],
                );
              },
            )));
  }
}
