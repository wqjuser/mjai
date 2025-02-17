
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/change_settings.dart';
import '../json_models/video_list_data.dart';
import '../net/my_api.dart';
import '../utils/common_methods.dart';
import 'limited_text.dart';

///视频列表的item
///
// ignore: must_be_immutable
class VideoItemView extends StatefulWidget {
  VideoListData videoData;
  final Function(VideoListData videoData) onPlayClick;
  final Function(VideoListData videoData) onDownload;
  final Function(VideoListData videoData) onExtend;

  VideoItemView(
      {super.key, required this.videoData, required this.onPlayClick, required this.onDownload, required this.onExtend});

  @override
  State<VideoItemView> createState() => VideoItemViewState();
}

class VideoItemViewState extends State<VideoItemView> {
  late VideoListData videoData;
  late MyApi myApi;
  String? videoUrl = '';
  String? thumbnailUrl = '';

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    videoData = widget.videoData;
    videoUrl = widget.videoData.video?['url'];
    thumbnailUrl = widget.videoData.video?['thumbnail'];
  }

  void refreshData(VideoListData data) {
    setState(() {
      videoData = data;
      videoUrl = data.video!['url'];
      thumbnailUrl = data.video!['thumbnail'];
      widget.videoData = data;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      children: [
        Expanded(
            child: thumbnailUrl != null && thumbnailUrl != ''
                ? Center(
                    child: Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
                          child: ExtendedImage.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Center(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
                          child: Container(
                            color: getRealDarkMode(settings) ? Colors.black.withAlpha(76) : Colors.transparent,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Center(
                        child: InkWell(
                          onTap: () {
                            widget.onPlayClick(widget.videoData);
                          },
                          child: Icon(
                            Icons.play_circle_outline,
                            color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ],
                  ))
                : Center(
                    child: Text(
                      '视频生成中...',
                      style: TextStyle(
                        color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                      ),
                    ),
                  )),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Tooltip(
              message: videoData.prompt,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: LimitedText(
                  text: videoData.prompt,
                  maxChars: 7,
                  settings: settings,
                ),
              ),
            ),
            Row(
              children: [
                Tooltip(
                  message: '下载',
                  child: IconButton(
                    icon: Icon(
                      Icons.download,
                      color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                    ),
                    onPressed: () {
                      // 下载按钮的功能实现
                      widget.onDownload(widget.videoData);
                    },
                  ),
                ),
                Tooltip(
                  message: '延长',
                  child: IconButton(
                    icon: Icon(
                      Icons.more_time,
                      color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                    ),
                    onPressed: () {
                      // 延长按钮的功能实现
                      widget.onExtend(widget.videoData);
                    },
                  ),
                )
              ],
            ),
          ],
        )
      ],
    );
  }
}
