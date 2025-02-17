import 'dart:io';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/video_player_view.dart';

import '../utils/file_picker_manager.dart';
import 'custom_dialog.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String imageUrl;
  final double previewWidth;
  final double previewHeight;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool isOnline;
  final bool isVideo;
  final String videoUrl;
  final VoidCallback? onDoubleTap;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;

  const ImagePreviewWidget({
    Key? key,
    required this.imageUrl,
    this.previewWidth = 80,
    this.previewHeight = 80,
    this.padding = const EdgeInsets.only(right: 5),
    this.radius = 8.0,
    this.isOnline = true,
    this.isVideo = false,
    this.videoUrl = '',
    this.onDoubleTap,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          // 使用 GestureDetector 替换最外层的点击处理
          onTap: () {
            if (isVideo) {
              _playVideo(context, settings);
            } else {
              _showFullScreenImage(context, settings);
            }
          },
          onDoubleTap: onDoubleTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 图片/视频封面
              isOnline
                  ? ExtendedImage.network(
                      imageUrl,
                      width: previewWidth,
                      height: previewHeight,
                      fit: fit,
                      alignment: alignment!,
                    )
                  : ExtendedImage.file(
                      File(imageUrl),
                      width: previewWidth,
                      height: previewHeight,
                      fit: fit,
                      alignment: alignment!,
                    ),
              // 播放按钮
              if (isVideo)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(76),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black.withAlpha(128),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, ChangeSettings settings) {
    MyApi myApi = MyApi();
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Stack(
            children: [
              ExtendedImageGesturePageView.builder(
                reverse: true,
                itemBuilder: (BuildContext context, int index) {
                  Widget image = isOnline
                      ? ExtendedImage.network(imageUrl, fit: BoxFit.contain, mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (state) {
                          return GestureConfig(
                            inPageView: true,
                            initialScale: 0.5,
                            minScale: 0.4,
                            maxScale: 1.0,
                            animationMaxScale: 1.0,
                            initialAlignment: InitialAlignment.center,
                          );
                        })
                      : ExtendedImage.file(File(imageUrl), fit: BoxFit.contain, mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (state) {
                          return GestureConfig(
                            inPageView: true,
                            initialScale: 0.5,
                            minScale: 0.4,
                            maxScale: 1.0,
                            animationMaxScale: 1.0,
                            initialAlignment: InitialAlignment.center,
                          );
                        });
                  return Container(
                    padding: const EdgeInsets.all(5.0),
                    child: image,
                  );
                },
                itemCount: 1,
              ),
              Positioned(
                bottom: 20,
                right: 0,
                left: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          child: const Icon(
                            Icons.close,
                            size: 30,
                            color: Colors.white,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          child: const Icon(
                            Icons.download,
                            size: 30,
                            color: Colors.white,
                          ),
                          onTap: () async {
                            String extension = imageUrl.split('.').last;
                            String currentTime = getCurrentTimestamp();
                            String? outputFile = await FilePickerManager().saveFile(
                              dialogTitle: '选择文件保存位置',
                              fileName: '$currentTime.$extension',
                            );
                            if (outputFile != null) {
                              await myApi.downloadSth(imageUrl, outputFile, onReceiveProgress: (progress, total) {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (getRealDarkMode(settings))
                IgnorePointer(
                    child: Container(
                  color: Colors.black.withAlpha(76),
                ))
            ],
          );
        },
      );
    }
  }

  void _playVideo(BuildContext context, ChangeSettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          maxWidth: 600,
          title: '',
          singleLineTitle: true,
          contentBackgroundColor: settings.getBackgroundColor(),
          titleColor: settings.getForegroundColor(),
          content: VideoPlayerView(videoUrl: videoUrl),
        );
      },
    );
  }
}
