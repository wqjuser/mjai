import 'package:flutter/material.dart';
import '../json_models/video_list_data.dart';

class VideoGridItem extends StatefulWidget {
  final VideoListData item;
  final Animation<double> animation;
  final VoidCallback onLongPress;

  const VideoGridItem({
    super.key,
    required this.item,
    required this.animation,
    required this.onLongPress,
  });

  @override
  State<VideoGridItem> createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<VideoGridItem> {

  void refresh(int position, VideoListData data){

  }
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        child: Container(
          margin: const EdgeInsets.all(3.0),
          color: Colors.blue,
          child: Center(child: Container()),
        ),
      ),
    );
  }
}
