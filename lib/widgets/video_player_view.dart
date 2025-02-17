// import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerView extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;

  const VideoPlayerView({super.key, required this.videoUrl, this.aspectRatio = 16.0 / 9.0});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerView> {
  bool _isVideoPlayerInitialized = false;

  // Create a [Player] to control playback.
  late final player = Player(configuration: PlayerConfiguration(ready: () {
    setState(() {
      _isVideoPlayerInitialized = true;
    });
  }));

  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }
  Future<void> _initVideoPlayer() async {
    player.open(Media(widget.videoUrl));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isVideoPlayerInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Video(controller: controller),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
