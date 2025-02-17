import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'dart:async';

import '../json_models/music_response_entity.dart';

class MusicPlayerWidget extends StatefulWidget {
  final MusicResponseClips musicData; // 传入音乐数据

  const MusicPlayerWidget({Key? key, required this.musicData}) : super(key: key);

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.5; // 初始音量
  OverlayEntry? _overlayEntry;
  final GlobalKey _volumeButtonKey = GlobalKey(); // 用于获取音量按钮位置
  bool _isVolumeSliderVisible = false; // 控制音量条的显示与隐藏
  List<StreamSubscription> streams = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _duration = Duration(milliseconds: ((widget.musicData.metadata?.duration!) * 1000).toInt());
    initData();
  }

  void initData() async {
    showHint('正在初始化音频数据...', showType: 5);
    if (widget.musicData.audioUrl != null) {
      _duration = await _audioPlayer.setUrl(widget.musicData.audioUrl!) ?? Duration.zero;
    }
    dismissHint();
    try {
      // 监听音频时长变化
      streams.add(_audioPlayer.durationStream.listen((duration) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }));
    } catch (e) {
      commonPrint(e);
    }
    try {
      // 监听音频播放位置变化
      streams.add(_audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      }));
    } catch (e) {
      commonPrint(e);
    }

  }

  // 播放和暂停控制
  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      if (widget.musicData.audioUrl != null) {
        _audioPlayer.play();
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // 拖动进度条
  void _seek(double seconds) {
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
  }

  // 设置音量 (带防抖)
  void _setVolume(double volume) {
    _audioPlayer.setVolume(volume); // 异步更新音量
  }

  // 移除音量条的 OverlayEntry
  void _removeVolumeSlider() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _removeVolumeSlider();
    for (var it in streams) {
      it.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // 格式化时间
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 获取音量按钮的位置和宽度
  Offset _getVolumeButtonPosition() {
    final RenderBox renderBox = _volumeButtonKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }

  double _getVolumeButtonWidth() {
    final RenderBox renderBox = _volumeButtonKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size.width;
  }

  // 显示音量条
  void _showVolumeSlider(BuildContext context) {
    if (_overlayEntry == null) {
      final overlay = Overlay.of(context);
      final Offset volumeButtonPosition = _getVolumeButtonPosition();
      final double volumeButtonWidth = _getVolumeButtonWidth();

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: volumeButtonPosition.dx + volumeButtonWidth / 2 - 20, // 确保音量条居中显示在音量按钮的上方
          top: volumeButtonPosition.dy - 160, // 在按钮的上方显示音量条
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 150,
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0, right: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: _volume,
                            min: 0,
                            max: 1,
                            activeColor: Colors.red,
                            inactiveColor: Colors.grey,
                            onChanged: (value) {
                              // 实时更新 UI, 但不设置音量
                              setState(() {
                                _volume = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _setVolume(value);
                            },
                          ),
                        ),
                      ),
                      Text(
                        "${(_volume * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );

      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 显示歌曲封面
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(widget.musicData.imageUrl), // 默认图片
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // 显示歌曲名称
          Text(
            widget.musicData.title == '' ? '无标题' : widget.musicData.title!,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // 显示作者名称
          Text(
            widget.musicData.displayName == '' ? '未知歌手' : widget.musicData.displayName!,
            style: TextStyle(
              fontSize: 18,
              color: settings.getForegroundColor(),
            ),
          ),
          const SizedBox(height: 20),
          // 播放时间和进度条
          Slider(
            activeColor: settings.getSelectedBgColor(),
            inactiveColor: Colors.grey,
            min: 0.0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.toDouble(),
            onChanged: (value) {
              _seek(value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: settings.getForegroundColor()),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: settings.getForegroundColor()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 播放按钮和音量控制放在一行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 播放/暂停按钮
              IconButton(
                iconSize: 64,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: settings.getSelectedBgColor(),
                ),
                onPressed: _playPause,
              ),
              Visibility(
                  visible: false,
                  child: Column(
                    children: [
                      const SizedBox(width: 30),
                      // 音量控制按钮与音量条
                      IconButton(
                        key: _volumeButtonKey,
                        icon: const Icon(Icons.volume_up, color: Colors.blue, size: 32),
                        onPressed: () {
                          setState(() {
                            _isVolumeSliderVisible = !_isVolumeSliderVisible;
                            _showVolumeSlider(context); // 点击显示或隐藏音量条
                          });
                        },
                      ),
                    ],
                  ))
            ],
          ),
        ],
      ),
    );
  }
}
