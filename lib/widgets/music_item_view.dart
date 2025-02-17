import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import '../json_models/music_response_entity.dart';
import '../net/my_api.dart';
import '../utils/common_methods.dart';
import 'limited_text.dart';

/// 音乐列表的item
// ignore: must_be_immutable
class MusicItemView extends StatefulWidget {
  MusicResponseClips musicData;
  final Function(MusicResponseClips musicData) onPlayClick;
  final Function(MusicResponseClips musicData) onDownload;
  final Function(MusicResponseClips musicData) onExtend;

  MusicItemView(
      {super.key, required this.musicData, required this.onPlayClick, required this.onDownload, required this.onExtend});

  @override
  State<MusicItemView> createState() => MusicItemViewState();
}

class MusicItemViewState extends State<MusicItemView> {
  late MusicResponseClips musicData;
  late MyApi myApi;
  String? audioUrl = '';
  String? imageUrl = '';
  String? status = '';

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    musicData = widget.musicData;
    audioUrl = widget.musicData.audioUrl;
    imageUrl = widget.musicData.imageUrl;
    status = widget.musicData.status;
  }

  void refreshData(MusicResponseClips data) {
    setState(() {
      musicData = data;
      widget.musicData = data;
      audioUrl = data.audioUrl;
      imageUrl = data.imageUrl;
      status = data.status;
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
            child: status != null && status == 'complete'
                ? Center(
                    child: Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
                          child: ExtendedImage.network(
                            imageUrl!,
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
                            widget.onPlayClick(widget.musicData);
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
                      '音乐生成中...',
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
              message: musicData.title,
              child: Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 3, left: 10),
                child: LimitedText(
                  text: musicData.title == '' ? '无标题' : musicData.title!,
                  maxChars: 7,
                  settings: settings,
                ),
              ),
            ),
            Row(
              children: [
                Visibility(
                  visible: status != null && status == 'complete',
                  child: Tooltip(
                    message: '下载',
                    child: IconButton(
                      icon: Icon(
                        Icons.download,
                        color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                      ),
                      onPressed: () {
                        // 下载按钮的功能实现
                        widget.onDownload(widget.musicData);
                      },
                    ),
                  ),
                ),
                Visibility(
                    visible: status != null && status == 'complete',
                    child: Tooltip(
                      message: '延长',
                      child: IconButton(
                        icon: Icon(
                          Icons.more_time,
                          color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                        ),
                        onPressed: () {
                          // 延长按钮的功能实现
                          widget.onExtend(widget.musicData);
                        },
                      ),
                    ))
              ],
            ),
          ],
        )
      ],
    );
  }
}
