import 'dart:async';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/screen_resolution_singleton.dart';
import '../config/global_params.dart';
import '../json_models/item_model.dart';
import 'common_dropdown.dart';
import 'custom_image_view.dart';

// ignore: must_be_immutable
class ImageManipulationItem extends StatefulWidget {
  String index;
  String prompt;
  String useImagePath;
  String imageChangeType;
  String characterPreset;
  final int allScenes;
  bool isAlreadyUpScale = false;
  bool isAlreadyUpScaleRepair = false;
  bool isAlreadyVariation = false;
  bool useFix = false; //这里实际上是ADetail是否启用
  bool useControlnet = false;
  int drawEngine = 0;
  List<String> imageBase64List;
  List<String> imageUrlList;
  List<String> characterPresets;
  List<int>? imagesDownloadStatus = [0, 0, 0, 0];
  bool? isSingleImageDownloaded = false;
  List<Map<String, dynamic>> controlNetOptions;
  List<Map<String, dynamic>> aDetailsOptions;
  String taskId;
  String imageId;
  String useImageUrl; //逆天的知数云需要一个可直接访问的图片url地址才能反推图片tag
  String operatedImageId; //操作后的图片id，包括高清，变换，高低变换，缩小，平移，每个操作后图片id均会变化
  List<String> actions = [];
  List<String> actions2 = [];
  List<dynamic> actions3 = []; //生图之后的操作项数组，自有账号的mj才会有这个值
  List<dynamic> actions4 = []; //放大之后的操作项数组，自有账号的mj才会有这个值
  int useAiMode;
  int selectedImagePosition = -1;
  Function(String currentIndex) onMergeDown;
  Function(String currentIndex) onMergeUp;
  Function(String currentIndex) onAddDown;
  Function(String currentIndex) onAddUp;
  Function(String currentIndex) onDelete;
  Function(String currentIndex) aiScene;
  Function(String currentIndex) transScene;
  Function(String currentIndex) sceneToImage;
  Function(String currentIndex) onUpScale;
  Function(String currentIndex, {int type}) onVariation;
  Function(String currentIndex) onUpScaleRepair;
  Function(String currentIndex) onSelectImage;
  Function(String currentIndex) onChangeUseFix;
  Function(String currentIndex, int position, List<String> images) onImageTapped;
  Function(String currentIndex, int position, List<String> images) onImageSaveTapped;
  Function(String currentIndex) onVoiceTapped;
  Function(String currentIndex) onSingleImageTapped;
  Function(String currentIndex)? onSingleImageSaveTapped;
  Function(String currentIndex)? onReasoningTagsTapped;
  Function(String currentIndex) onUseControlNet;
  Function(String currentIndex, String type) onPresetsChanged;
  Function(String currentIndex, String type) onTypeChanged;
  Function(String currentIndex, String type) onSelectCustom;
  Function(String currentIndex, String content) onContentChanged;
  TextEditingController aiSceneController;
  TextEditingController selfSceneController;
  TextEditingController transSceneController;
  TextEditingController contentController;
  ScrollController scrollController;
  ScrollController scrollControllerTrans;

  ImageManipulationItem(
      {super.key,
      required this.index,
      required this.prompt,
      required this.allScenes,
      required this.onMergeDown,
      required this.onAddDown,
      required this.onMergeUp,
      required this.onAddUp,
      required this.onDelete,
      required this.aiScene,
      required this.transScene,
      required this.controlNetOptions,
      required this.aDetailsOptions,
      required this.sceneToImage,
      required this.drawEngine,
      required this.aiSceneController,
      required this.selfSceneController,
      required this.transSceneController,
      required this.contentController,
      required this.scrollController,
      this.imageId = '',
      this.operatedImageId = '',
      required this.actions,
      required this.actions2,
      required this.actions3,
      required this.actions4,
      this.taskId = '',
      required this.imageUrlList,
      required this.useImageUrl,
      this.selectedImagePosition = -1,
      required this.scrollControllerTrans,
      required this.onReasoningTagsTapped,
      required this.imageBase64List,
      required this.onImageTapped,
      required this.useImagePath,
      required this.onTypeChanged,
      required this.imageChangeType,
      required this.onChangeUseFix,
      required this.onSingleImageTapped,
      required this.isAlreadyUpScale,
      required this.isAlreadyUpScaleRepair,
      required this.onVoiceTapped,
      required this.useAiMode,
      required this.onUpScale,
      required this.onVariation,
      required this.onUpScaleRepair,
      required this.onSelectImage,
      required this.onPresetsChanged,
      required this.onSelectCustom,
      required this.characterPresets,
      required this.onImageSaveTapped,
      required this.imagesDownloadStatus,
      required this.isSingleImageDownloaded,
      required this.onSingleImageSaveTapped,
      required this.useFix,
      required this.useControlnet,
      required this.onUseControlNet,
      required this.onContentChanged,
      required this.characterPreset});

  @override
  State<StatefulWidget> createState() => ImageManipulationItemState();
}

class ImageManipulationItemState extends State<ImageManipulationItem> {
  late TextEditingController aiSceneController;
  late TextEditingController selfSceneController;
  late TextEditingController transSceneController;
  late TextEditingController contentController;
  late ScrollController scrollController;
  late ScrollController scrollControllerTrans;
  late List<String> imageBase64List;
  late List<String> imageUrlsList;
  List<String> imageChangeTypes = ['0.无', '1.从上到下', '2.从下到上', '3.从左到右', '4.从右到左', '5.自动判断'];
  late List<String> characterPresets;
  late String imageChangeType;
  Timer? _debounce;
  int drawEngine = 0;
  late List<MJItemModel> menuItems;
  late List<MJItemModel> subMenuItems;
  String? screenSize = ScreenResolutionSingleton.instance.screenResolution;
  var deleteSize = 175;

  void onChangeCharacterPreset(String type) {
    if (type == '自定义') {
      widget.onSelectCustom(widget.index, type);
    } else {
      widget.onPresetsChanged(widget.index, type);
    }
  }

  void updateCharacterPresets(List<String> newCharacterPresets) {
    setState(() {
      characterPresets = newCharacterPresets;
    });
  }

  void onChangeImageChangeType(String type) {
    widget.onTypeChanged(widget.index, type);
  }

  void changeDrawEngine(int inputDrawEngine) {
    setState(() {
      drawEngine = inputDrawEngine;
    });
  }

  @override
  void initState() {
    aiSceneController = widget.aiSceneController;
    selfSceneController = widget.selfSceneController;
    transSceneController = widget.transSceneController;
    contentController = widget.contentController;
    scrollController = widget.scrollController;
    scrollControllerTrans = widget.scrollControllerTrans;
    imageBase64List = widget.imageBase64List;
    imageUrlsList = widget.imageUrlList;
    imageChangeType = widget.imageChangeType;
    characterPresets = widget.characterPresets.obs;
    drawEngine = widget.drawEngine;
    menuItems = [
      MJItemModel(['放大']),
      MJItemModel(['变换'])
    ];
    subMenuItems = [
      MJItemModel(['放大1', '放大2', '放大3', '放大4']),
      MJItemModel(['变换1', '变换2', '变换3', '变换4'])
    ];
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    deleteSize = (((screenSize == '4K')
                ? 120
                : (screenSize == '2K')
                    ? 150
                    : (screenSize == '1080p')
                        ? 180
                        : 210) *
            (ratio < 2 ? 2 : ratio))
        .toInt();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SizedBox(
      height: 370,
      width: MediaQuery.of(context).size.width,
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(), // 设置内容限制为填充父布局
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(
                    color: GlobalParams.themeColor,
                    width: 1.0,
                  ),
                  right: BorderSide(
                    color: GlobalParams.themeColor,
                    width: 1.0,
                  ),
                  bottom: BorderSide(
                    color: GlobalParams.themeColor,
                    width: 1.0,
                  )),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      widget.index,
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 370.0, // 设置线的高度
                  color: GlobalParams.themeColor, // 设置线的颜色
                ),
                SizedBox(
                  height: 370,
                  width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                  child: Stack(
                    children: [
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AutoSizeTextField(
                          cursorColor: Colors.white,
                          fullwidth: false,
                          controller: contentController,
                          onChanged: (content) {
                            if (_debounce != null) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(const Duration(milliseconds: 1000), () {
                              widget.onContentChanged(widget.index, content);
                            });
                          },
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            shadows: [
                              Shadow(
                                color: Colors.grey.withAlpha(128),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          // 将文本垂直居中
                          minFontSize: 14,
                          maxLines: null,
                          scrollPadding: EdgeInsets.zero,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isCollapsed: true,
                          ), // 控制文本对齐方式
                        ),
                      )),
                      Positioned(
                        bottom: 5.0,
                        right: 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              InkWell(
                                child: Tooltip(
                                  message: '在上方插入场景',
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: settings.getSelectedBgColor(),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/images/add_up.svg',
                                      semanticsLabel: '在上方插入场景',
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  widget.onAddUp(widget.index);
                                },
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              InkWell(
                                child: Tooltip(
                                  message: '在下方插入场景',
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: settings.getSelectedBgColor(),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/images/add_down.svg',
                                      semanticsLabel: '在下方插入场景',
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  widget.onAddDown(widget.index);
                                },
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              widget.index != '1'
                                  ? InkWell(
                                      child: Tooltip(
                                        message: '向上合并',
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: settings.getSelectedBgColor(),
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/images/merge_up.svg',
                                            semanticsLabel: '向上合并',
                                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        widget.onMergeUp(widget.index);
                                      },
                                    )
                                  : Container(),
                              const SizedBox(
                                width: 5,
                              ),
                              int.parse(widget.index) != widget.allScenes
                                  ? InkWell(
                                      child: Tooltip(
                                        message: '向下合并',
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: settings.getSelectedBgColor(),
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/images/merge_down.svg',
                                            semanticsLabel: '向下合并',
                                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        widget.onMergeDown(widget.index);
                                      },
                                    )
                                  : Container(),
                              const SizedBox(
                                width: 5,
                              ),
                              InkWell(
                                child: Tooltip(
                                  message: '删除此场景',
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: settings.getSelectedBgColor(),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/images/delete.svg',
                                      semanticsLabel: '删除此场景',
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  widget.onDelete(widget.index);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 370, // 设置线的高度
                  color: GlobalParams.themeColor, // 设置线的颜色
                ),
                SizedBox(
                  height: 370,
                  width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 5),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: TextField(
                          controller: aiSceneController,
                          scrollController: scrollController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 10,
                          minLines: 10,
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            shadows: [
                              Shadow(
                                color: Colors.grey.withAlpha(128),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '自行输入或由AI处理后的场景描述',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      )),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: TextField(
                          controller: transSceneController,
                          scrollController: scrollControllerTrans,
                          maxLines: 10,
                          minLines: 10,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            shadows: [
                              Shadow(
                                color: Colors.grey.withAlpha(128),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '翻译后的场景描述',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      )),
                      Visibility(
                        visible: widget.drawEngine == 0,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            children: <Widget>[
                              const Text('人物预设', style: TextStyle(color: Colors.yellowAccent)),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: CommonDropdownWidget(
                                dropdownData: characterPresets,
                                selectedValue: widget.characterPreset,
                                onChangeValue: onChangeCharacterPreset,
                              )),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.drawEngine == 0,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 6, right: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      widget.onChangeUseFix(widget.index);
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      !widget.useFix ? '启用ADetail' : '已启用ADetail',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      widget.onUseControlNet(widget.index);
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      !widget.useControlnet ? '启用controlnet' : '已启用controlnet',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: settings.getSelectedBgColor(),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    widget.onVoiceTapped(widget.index);
                                  },
                                  child: const Text('配音')),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: settings.getSelectedBgColor(),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    widget.aiScene(widget.index);
                                  },
                                  child: const Text('推理')),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: settings.getSelectedBgColor(),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    widget.transScene(widget.index);
                                  },
                                  child: const Text('翻译')),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: settings.getSelectedBgColor(),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    widget.sceneToImage(widget.index);
                                  },
                                  child: const Text('生图')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 370, // 设置线的高度
                  color: GlobalParams.themeColor, // 设置线的颜色
                ),
                SizedBox(
                  height: 370,
                  width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, top: 6),
                    child: CustomImageView(
                      imageUrls: imageUrlsList,
                      imagePaths: imageBase64List,
                      onImageTap: (position, allImagePaths) {
                        widget.onImageTapped(widget.index, position, allImagePaths);
                      },
                      onImageSaveTap: (position, allImagePaths) {
                        widget.onImageSaveTapped(widget.index, position, allImagePaths);
                      },
                      imagesDownloadStatus: widget.imagesDownloadStatus,
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 370, // 设置线的高度
                  color: GlobalParams.themeColor, // 设置线的颜色
                ),
                SizedBox(
                  height: 370,
                  width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                  child: Container(
                    child: widget.useImagePath == ''
                        ? Stack(
                            children: [
                              Center(
                                  child: Padding(
                                padding: const EdgeInsets.only(left: 6, right: 6),
                                child: Text(
                                  '请从左边的生成图片中选择图片或者点击上传按钮',
                                  style: TextStyle(
                                    color: Colors.yellowAccent,
                                    shadows: [
                                      Shadow(
                                        color: Colors.grey.withAlpha(128),
                                        offset: const Offset(0, 2),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.start,
                                ),
                              )),
                              Positioned(
                                bottom: 20.0,
                                left: 0,
                                right: 0,
                                child: Center(
                                    child: InkWell(
                                  child: Tooltip(
                                    message: '上传图片',
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: settings.getSelectedBgColor(),
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/upload_image.svg',
                                        semanticsLabel: '上传图片',
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    widget.onSelectImage(widget.index);
                                  },
                                )),
                              ),
                            ],
                          )
                        : LayoutBuilder(builder: (context, constraints) {
                            return Stack(children: [
                              InkWell(
                                onTap: () {
                                  widget.onSingleImageTapped(widget.index);
                                },
                                child: Container(
                                  width: constraints.maxWidth, // 设置为Expanded的宽度
                                  height: constraints.maxHeight, // 设置为Expanded的高度
                                  margin: const EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: ExtendedImage.network(widget.useImagePath, fit: BoxFit.cover)),
                                ),
                              ),
                              Positioned(
                                bottom: 20.0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Column(
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        InkWell(
                                          child: Tooltip(
                                            message: !widget.isAlreadyUpScale ? '高清放大' : '已高清放大，无需再次点击',
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: settings.getSelectedBgColor(),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/images/up_scale.svg',
                                                semanticsLabel: !widget.isAlreadyUpScale ? '高清放大' : '已高清放大，无需再次点击',
                                                colorFilter: ColorFilter.mode(
                                                    !widget.isAlreadyUpScale ? Colors.white : Colors.blue, BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            if (!widget.isAlreadyUpScale) {
                                              widget.onUpScale(widget.index);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          child: Tooltip(
                                            message: !widget.isAlreadyUpScaleRepair ? '图生图重绘' : '已图生图重绘,可再次点击重绘',
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: settings.getSelectedBgColor(),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/images/up_scale_repair.svg',
                                                semanticsLabel: !widget.isAlreadyUpScaleRepair ? '图生图重绘' : '已图生图重绘,可再次点击重绘',
                                                colorFilter: ColorFilter.mode(
                                                    !widget.isAlreadyUpScaleRepair ? Colors.white : Colors.blue, BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            widget.onUpScaleRepair(widget.index);
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          child: Tooltip(
                                            message: '上传图片',
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: settings.getSelectedBgColor(),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/images/upload_image.svg',
                                                semanticsLabel: '上传图片',
                                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            widget.onSelectImage(widget.index);
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          child: Tooltip(
                                            message: !widget.isSingleImageDownloaded! ? '下载图片' : '图片已下载',
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: settings.getSelectedBgColor(),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/images/download_image.svg',
                                                semanticsLabel: !widget.isSingleImageDownloaded! ? '下载图片' : '图片已下载',
                                                colorFilter: ColorFilter.mode(
                                                    !widget.isSingleImageDownloaded! ? Colors.white : Colors.blue,
                                                    BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            widget.onSingleImageSaveTapped!(widget.index);
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          child: Tooltip(
                                            message: '反推关键词',
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              padding: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: settings.getSelectedBgColor(),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/images/reasoning.svg',
                                                semanticsLabel: '反推关键词',
                                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            widget.onReasoningTagsTapped!(widget.index);
                                          },
                                        )
                                      ]),
                                      Visibility(
                                          visible: drawEngine == 1 || drawEngine == 2,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Visibility(
                                                      //新版本的mj放大后没有这个按钮了
                                                      visible: false,
                                                      child: InkWell(
                                                        child: Tooltip(
                                                          message: !widget.isAlreadyVariation ? '图片变换' : '图片已变换,可再次点击重新变换',
                                                          child: Container(
                                                            width: 40,
                                                            height: 40,
                                                            padding: const EdgeInsets.all(8.0),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.circular(20.0),
                                                            ),
                                                            child: SvgPicture.asset(
                                                              'assets/images/variation.svg',
                                                              semanticsLabel:
                                                                  !widget.isAlreadyVariation ? '图片变换' : '图片已变换,可再次点击重新变换',
                                                              // colorFilter: ColorFilter.mode(!widget.isAlreadyUpScaleRepair ? Colors.black : Colors.blue, BlendMode.srcIn),
                                                            ),
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          widget.onVariation(widget.index);
                                                        },
                                                      )),
                                                  Visibility(
                                                      visible: widget.isAlreadyUpScale,
                                                      child: Row(
                                                        children: [
                                                          const SizedBox(width: 6),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: !widget.isAlreadyVariation ? '图片低变换' : '图片已低变换,可再次点击重新低变换',
                                                              child: Stack(
                                                                children: [
                                                                  Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    decoration: BoxDecoration(
                                                                      color: settings.getSelectedBgColor(),
                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                    ),
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/variation.svg',
                                                                      semanticsLabel: !widget.isAlreadyVariation
                                                                          ? '图片低变换'
                                                                          : '图片已低变换,可再次点击重新低变换',
                                                                      colorFilter: ColorFilter.mode(
                                                                          !widget.isAlreadyUpScaleRepair
                                                                              ? Colors.white
                                                                              : Colors.blue,
                                                                          BlendMode.srcIn),
                                                                    ),
                                                                  ),
                                                                  const Positioned(
                                                                      bottom: 9,
                                                                      right: 12,
                                                                      child: Text(
                                                                        'L',
                                                                        style: TextStyle(
                                                                            color: Colors.black,
                                                                            fontSize: 12,
                                                                            fontWeight: FontWeight.bold),
                                                                      ))
                                                                ],
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 2);
                                                            },
                                                          ),
                                                          const SizedBox(width: 6),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: !widget.isAlreadyVariation ? '图片高变换' : '图片已高变换,可再次点击重新高变换',
                                                              child: Stack(
                                                                children: [
                                                                  Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    decoration: BoxDecoration(
                                                                      color: settings.getSelectedBgColor(),
                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                    ),
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/variation.svg',
                                                                      semanticsLabel: !widget.isAlreadyVariation
                                                                          ? '图片高变换'
                                                                          : '图片已高变换,可再次点击重新高变换',
                                                                      colorFilter: ColorFilter.mode(
                                                                          !widget.isAlreadyUpScaleRepair
                                                                              ? Colors.white
                                                                              : Colors.blue,
                                                                          BlendMode.srcIn),
                                                                    ),
                                                                  ),
                                                                  const Positioned(
                                                                      bottom: 9,
                                                                      right: 12,
                                                                      child: Text(
                                                                        'H',
                                                                        style: TextStyle(
                                                                            color: Colors.black,
                                                                            fontSize: 12,
                                                                            fontWeight: FontWeight.bold),
                                                                      ))
                                                                ],
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 3);
                                                            },
                                                          ),
                                                          const SizedBox(width: 6),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message:
                                                                  !widget.isAlreadyVariation ? '图片缩小2倍' : '图片已缩小2倍,可再次点击重新缩小2倍',
                                                              child: Stack(
                                                                children: [
                                                                  Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    decoration: BoxDecoration(
                                                                      color: settings.getSelectedBgColor(),
                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                    ),
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/zoom.svg',
                                                                      semanticsLabel: !widget.isAlreadyVariation
                                                                          ? '图片缩小2倍'
                                                                          : '图片已缩小2倍,可再次点击重新缩小2倍',
                                                                      colorFilter: ColorFilter.mode(
                                                                          !widget.isAlreadyUpScaleRepair
                                                                              ? Colors.white
                                                                              : Colors.blue,
                                                                          BlendMode.srcIn),
                                                                    ),
                                                                  ),
                                                                  const Positioned(
                                                                    bottom: 0,
                                                                    right: 0,
                                                                    left: 0,
                                                                    child: Center(
                                                                      child: Text(
                                                                        '2.0',
                                                                        style: TextStyle(
                                                                            color: Colors.black,
                                                                            fontSize: 10,
                                                                            fontWeight: FontWeight.bold),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 5);
                                                            },
                                                          ),
                                                          const SizedBox(width: 6),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: !widget.isAlreadyVariation
                                                                  ? '图片缩小1.5倍'
                                                                  : '图片已缩小1.5倍,可再次点击重新缩小1.5倍',
                                                              child: Stack(
                                                                children: [
                                                                  Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    decoration: BoxDecoration(
                                                                      color: settings.getSelectedBgColor(),
                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                    ),
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/zoom.svg',
                                                                      semanticsLabel: !widget.isAlreadyVariation
                                                                          ? '图片缩小1.5倍'
                                                                          : '图片已缩小1.5倍,可再次点击重新缩小1.5倍',
                                                                      colorFilter: ColorFilter.mode(
                                                                          !widget.isAlreadyUpScaleRepair
                                                                              ? Colors.white
                                                                              : Colors.blue,
                                                                          BlendMode.srcIn),
                                                                    ),
                                                                  ),
                                                                  const Positioned(
                                                                    bottom: 0,
                                                                    right: 0,
                                                                    left: 0,
                                                                    child: Center(
                                                                      child: Text(
                                                                        '1.5',
                                                                        style: TextStyle(
                                                                            color: Colors.black,
                                                                            fontSize: 10,
                                                                            fontWeight: FontWeight.bold),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 6);
                                                            },
                                                          ),
                                                        ],
                                                      ))
                                                ],
                                              ),
                                              Visibility(
                                                  visible: widget.isAlreadyUpScale,
                                                  child: Column(
                                                    children: [
                                                      const SizedBox(
                                                        height: 6,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: '向左平移',
                                                              child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    color: settings.getSelectedBgColor(),
                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                  ),
                                                                  child: Transform.rotate(
                                                                    angle: -90 * 3.1415926535897932 / 180,
                                                                    // 角度转换为弧度
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/arrow_up.svg',
                                                                      semanticsLabel: '向左平移',
                                                                      // colorFilter: ColorFilter.mode(
                                                                      //     !widget.isAlreadyUpScaleRepair
                                                                      //         ? Colors.white
                                                                      //         : Colors.blue,
                                                                      //     BlendMode.srcIn),
                                                                    ),
                                                                  )),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 8);
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: '向右平移',
                                                              child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    color: settings.getSelectedBgColor(),
                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                  ),
                                                                  child: Transform.rotate(
                                                                    angle: 90 * 3.1415926535897932 / 180,
                                                                    // 角度转换为弧度
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/arrow_up.svg',
                                                                      semanticsLabel: '向右平移',
                                                                      // colorFilter: ColorFilter.mode(
                                                                      //     !widget.isAlreadyUpScaleRepair
                                                                      //         ? Colors.white
                                                                      //         : Colors.blue,
                                                                      //     BlendMode.srcIn),
                                                                    ),
                                                                  )),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 9);
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: '向上平移',
                                                              child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    color: settings.getSelectedBgColor(),
                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                  ),
                                                                  child: Transform.rotate(
                                                                    angle: 0 * 3.1415926535897932 / 180,
                                                                    // 角度转换为弧度
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/arrow_up.svg',
                                                                      semanticsLabel: '向上平移',
                                                                      // colorFilter: ColorFilter.mode(
                                                                      //     !widget.isAlreadyUpScaleRepair
                                                                      //         ? Colors.white
                                                                      //         : Colors.blue,
                                                                      //     BlendMode.srcIn),
                                                                    ),
                                                                  )),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 10);
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          InkWell(
                                                            child: Tooltip(
                                                              message: '向下平移',
                                                              child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    color: settings.getSelectedBgColor(),
                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                  ),
                                                                  child: Transform.rotate(
                                                                    angle: 180 * 3.1415926535897932 / 180,
                                                                    // 角度转换为弧度
                                                                    child: SvgPicture.asset(
                                                                      'assets/images/arrow_up.svg',
                                                                      semanticsLabel: '向下平移',
                                                                      // colorFilter: ColorFilter.mode(
                                                                      //     !widget.isAlreadyUpScaleRepair
                                                                      //         ? Colors.white
                                                                      //         : Colors.blue,
                                                                      //     BlendMode.srcIn),
                                                                    ),
                                                                  )),
                                                            ),
                                                            onTap: () {
                                                              widget.onVariation(widget.index, type: 11);
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ))
                                            ],
                                          )),
                                    ],
                                  ),
                                ),
                              )
                            ]);
                          }),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 370, // 设置线的高度
                  color: GlobalParams.themeColor, // 设置线的颜色
                ),
                Expanded(
                  child: Center(
                    child: Visibility(
                        visible: true,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          child: Center(
                              child: CommonDropdownWidget(
                            dropdownData: imageChangeTypes,
                            selectedValue: widget.imageChangeType,
                            onChangeValue: onChangeImageChangeType,
                          )),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
