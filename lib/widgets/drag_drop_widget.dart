import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class DragDropWidget extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 拖拽开始的回调
  final Function(DropEventDetails)? onDragEntered;

  /// 拖拽中的回调
  final Function(DropEventDetails)? onDragUpdated;

  /// 拖拽结束的回调
  final Function(DropEventDetails)? onDragExited;

  /// 放下文件时的回调
  final Function(DropDoneDetails)? onDragDone;

  /// 拖拽取消的回调
  final Function()? onDragCanceled;

  /// 是否显示拖拽提示遮罩
  final bool showDropMask;

  /// 拖拽提示遮罩的背景色
  final Color dropMaskColor;

  /// 拖拽提示文本
  final String dropHintText;

  /// 拖拽提示文本颜色
  final Color dropHintTextColor;

  const DragDropWidget({
    Key? key,
    required this.child,
    this.onDragEntered,
    this.onDragUpdated,
    this.onDragExited,
    this.onDragDone,
    this.onDragCanceled,
    this.showDropMask = true,
    this.dropMaskColor = const Color(0x40000000),
    this.dropHintText = '拖拽文件到这里后松开拖拽即可',
    this.dropHintTextColor = Colors.white,
  }) : super(key: key);

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 底层子组件
        widget.child,

        // 拖拽处理层
        Positioned.fill(
          child: DropTarget(
            onDragEntered: (details) {
              setState(() => _isDragging = true);
              widget.onDragEntered?.call(details);
            },
            onDragUpdated: (details) {
              widget.onDragUpdated?.call(details);
            },
            onDragExited: (details) {
              setState(() => _isDragging = false);
              widget.onDragExited?.call(details);
            },
            onDragDone: (details) {
              setState(() => _isDragging = false);
              widget.onDragDone?.call(details);
            },
            child: _isDragging && widget.showDropMask
                ? Container(
                    color: widget.dropMaskColor,
                    child: Center(
                      child: Text(
                        widget.dropHintText,
                        style: TextStyle(
                          color: widget.dropHintTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
