import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/json_models/music_response_entity.dart';
import 'package:tuitu/widgets/music_item_view.dart';

class MusicView extends StatefulWidget {
  final List<MusicResponseClips> musicList;
  final Function(MusicResponseClips) onPlayClick;
  final Function(MusicResponseClips) onDownload;
  final Function(MusicResponseClips) onExtend;
  final Function(MusicResponseClips, int index) onDelete;

  const MusicView({
    Key? key,
    required this.musicList,
    required this.onPlayClick,
    required this.onDownload,
    required this.onExtend,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<MusicView> createState() => MusicViewState();
}

class MusicViewState extends State<MusicView> {
  List<GlobalKey<MusicItemViewState>> itemKeys = [];

  @override
  void initState() {
    super.initState();
  }

  void addItem(MusicResponseClips item, {int index = 0}) {
    setState(() {
      widget.musicList.insert(index, item);
    });
  }

  void clearList() {
    setState(() {
      widget.musicList.clear();
    });
  }

  void refreshItem(int index, MusicResponseClips data) {
    itemKeys[index].currentState?.refreshData(data);
    setState(() {
      widget.musicList[index] = data;
    });
  }

  void removeItem(int index) {
    setState(() {
      widget.musicList.removeAt(index);
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int count = (screenWidth / 240).floor(); // 假设每个图片最小宽度为320
    Orientation orientation = MediaQuery.of(context).orientation;
    if (Platform.isWindows || Platform.isWindows) {
      return count.clamp(5, 10); // 限制在4-10之间
    } else {
      return orientation == Orientation.landscape ? 2 : 1;
    }
  }

  Widget _buildItem(MusicResponseClips item, int index, GlobalKey<MusicItemViewState> itemKey, ChangeSettings settings) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        color: settings.getAppbarColor(),
        elevation: 5,
        shadowColor: Colors.black45,
        child: MusicItemView(
          key: itemKey,
          musicData: item,
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
    int itemCount = widget.musicList.length;
    int crossAxisCount = _calculateCrossAxisCount(context);
    itemKeys.clear();
    for (int i = 0; i < itemCount; i++) {
      GlobalKey<MusicItemViewState> itemKey = GlobalKey<MusicItemViewState>();
      itemKeys.add(itemKey);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return GestureDetector(
            onLongPress: () async {
              widget.onDelete(widget.musicList[index], index);
            },
            child: _buildItem(widget.musicList[index], index, itemKeys[index], settings));
      },
    );
  }
}
