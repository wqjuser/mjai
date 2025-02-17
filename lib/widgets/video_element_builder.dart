import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/widgets/image_preview_widget.dart';

class VideoElementBuilder extends MarkdownElementBuilder {
  final ChangeSettings settings;

  VideoElementBuilder(this.settings);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'video') {
      final videoUrl = element.attributes['src'];
      final coverUrl = element.attributes['cover'];
      return ImagePreviewWidget(imageUrl: coverUrl ?? '', isVideo: true, videoUrl: videoUrl ?? '',previewHeight: 200,previewWidth: 200,);
    }
    return null;
  }
}
