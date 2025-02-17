import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/json_models/video_list_data.dart';
import 'package:tuitu/widgets/video_item_view.dart';

/// 视频列表
class VideoView extends StatefulWidget {
  final List<VideoListData> videoList;
  final Function(VideoListData videoData) onPlayClick;
  final Function(VideoListData videoData) onDownload;
  final Function(VideoListData videoData) onExtend;
  final Function(VideoListData videoData, int index) onDelete;

  const VideoView(
      {super.key,
      required this.videoList,
      required this.onPlayClick,
      required this.onDownload,
      required this.onExtend,
      required this.onDelete});

  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
  List<GlobalKey<VideoItemViewState>> itemKeys = [];

  @override
  void initState() {
    super.initState();
  }

  void addItem(VideoListData item, {int index = 0}) {
    setState(() {
      widget.videoList.insert(index, item);
    });
  }

  void refreshItem(int index, VideoListData data) {
    itemKeys[index].currentState?.refreshData(data);
  }

  void removeItem(int index) {
    setState(() {
      widget.videoList.removeAt(index);
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int count = (screenWidth / 240).floor(); // 假设每个图片最小宽度为320
    Orientation orientation = MediaQuery.of(context).orientation;
    if (Platform.isWindows || Platform.isMacOS) {
      return count.clamp(5, 10); // 限制在4-10之间
    } else {
      return orientation == Orientation.landscape ? 2 : 1;
    }
  }

  void clearList() {
    setState(() {
      widget.videoList.clear();
    });
  }

  Widget _buildItem(VideoListData item, int index, GlobalKey<VideoItemViewState> itemKey, ChangeSettings settings) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: settings.getAppbarColor(),
        elevation: 5,
        shadowColor: Colors.black45,
        child: VideoItemView(
          key: itemKey,
          videoData: item,
          onPlayClick: widget.onPlayClick,
          onDownload: widget.onDownload,
          onExtend: widget.onExtend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    int imageCount = widget.videoList.length;
    int crossAxisCount = _calculateCrossAxisCount(context);
    itemKeys.clear();
    for (int i = 0; i < imageCount; i++) {
      GlobalKey<VideoItemViewState> itemKey = GlobalKey<VideoItemViewState>();
      itemKeys.add(itemKey);
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      itemCount: imageCount,
      itemBuilder: (context, index) {
        return GestureDetector(
            onLongPress: () async {
              widget.onDelete(widget.videoList[index], index);
            },
            child: _buildItem(widget.videoList[index], index, itemKeys[index], settings));
      },
    );
  }
}
