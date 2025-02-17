import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

class StackedImageViewer extends StatefulWidget {
  final List<String> imageSources;
  final StackedImageViewerController? controller;
  final Function(String imageBase64)? onImageLongPressed;
  final VoidCallback? onPressed;

  const StackedImageViewer({Key? key, required this.imageSources, this.controller, this.onImageLongPressed, this.onPressed})
      : super(key: key);

  @override
  State<StackedImageViewer> createState() => _StackedImageViewerState();
}

class _StackedImageViewerState extends State<StackedImageViewer> {
  void _removeImage(int index) {
    setState(() {
      widget.imageSources.removeAt(index);
      if (widget.imageSources.isEmpty) {
        widget.imageSources.add('');
      }
    });
    widget.controller?.refreshDisplay();
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._bindState(this);
  }

  void _refreshDisplay() {
    setState(() {});
  }

  Widget _buildImage(String src, int index, ChangeSettings sets) {
    bool isEmptySource = src.isEmpty;
    Widget imageWidget = isEmptySource
        ? Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: sets.getSelectedBgColor(),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: SvgPicture.asset(
              'assets/images/upload_image.svg',
              semanticsLabel: '上传图片',
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          )
        : (src.startsWith(RegExp(r'http|https'))
            ? Image.network(src, width: 40)
            : Image.memory(base64.decode(src.substring(src.indexOf(',') + 1)), width: 40));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          child: imageWidget,
          onTap: () {
            widget.onPressed?.call();
          },
          onLongPress: () {
            if (!isEmptySource && index == widget.imageSources.length - 1) {
              widget.onImageLongPressed!(widget.imageSources[index].split(',')[1]);
            }
          },
        ),
        if (!isEmptySource && index == widget.imageSources.length - 1) // 只在最上层的图片上加删除按钮
          Positioned(
            right: -5,
            top: -5,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double baseAngle = 30.0; // 基础倾斜角度
    final sets = context.watch<ChangeSettings>();
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: widget.imageSources.asMap().entries.map((entry) {
          int idx = entry.key;
          double angleIncrement = 5.0 * idx;
          // 如果是空字符串，不旋转
          double rotationAngle =
              entry.value.isEmpty ? 0.0 : (idx % 2 == 0 ? 1 : -1) * (baseAngle + angleIncrement) * (3.14159 / 180.0);
          return Transform.rotate(
            angle: rotationAngle,
            child: _buildImage(entry.value, idx, sets),
          );
        }).toList(),
      ),
    );
  }
}

class StackedImageViewerController {
  _StackedImageViewerState? _state;

  void _bindState(_StackedImageViewerState state) {
    _state = state;
  }

  void refreshDisplay() {
    _state?._refreshDisplay();
  }
}
