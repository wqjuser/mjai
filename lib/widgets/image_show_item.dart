import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'dart:math' as math;
import '../json_models/item_model.dart';
import '../utils/common_methods.dart';

// ignore: must_be_immutable
class ImageShowItem extends StatefulWidget {
  final List<ItemModel> menuItems;
  final List<ItemModel> menuItemsPublic;
  final List<ItemModel> menuItemsSwapFaced;
  final List<ItemModel> menuItemsCU;
  final List<ItemModel> menuItemsFS;
  final List<ItemModel> menuItemsMJ1;
  final List<ItemModel> menuItemsMJV6;
  final List<ItemModel> menuItemsMJ2;
  final List<ItemModel> menuItemsMJ2Square;
  final List<ItemModel> finalMenuItems;
  ImageItemModel imageItemModel;
  final String base64Image;
  final String imageUrl;
  final int position;
  final Function(int index, String base64Image, int position, int menuPosition, String menuTitle) onMenuItemClick;
  final Function(int position) onImageClick;
  final bool isInGallery;
  final bool showCheckbox;
  final bool isSelected;
  final Function(bool isSelected) onSelectionChanged;

  ImageShowItem({
    super.key,
    required this.menuItems,
    required this.menuItemsSwapFaced,
    required this.menuItemsCU,
    required this.menuItemsFS,
    required this.menuItemsMJ1,
    required this.menuItemsMJV6,
    required this.menuItemsMJ2,
    required this.menuItemsMJ2Square,
    required this.finalMenuItems,
    required this.imageItemModel,
    required this.base64Image,
    required this.position,
    required this.imageUrl,
    required this.onMenuItemClick,
    required this.onImageClick,
    required this.menuItemsPublic,
    this.isInGallery = false,
    this.showCheckbox = false,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<ImageShowItem> createState() => ImageShowItemState();
}

class ImageShowItemState extends State<ImageShowItem> with SingleTickerProviderStateMixin {
  late List<ItemModel> finalMenuItems;
  late ImageItemModel imageItemModel;
  String seed = '';
  String imageUrl = '';
  String base64Image = '';
  bool isMenuVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    seed = widget.imageItemModel.seed;
    imageUrl = widget.imageUrl;
    imageItemModel = widget.imageItemModel;
    base64Image = widget.base64Image;
    _initializeAnimation();
    _updateFinalMenuItems();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _updateFinalMenuItems() {
    bool isMJ = imageItemModel.isMj;
    bool isCU = imageItemModel.drawEngine == 3;
    bool isFS = imageItemModel.drawEngine == 4;
    bool isUpScale = imageItemModel.isUpScaled;
    bool isSwapFace = imageItemModel.isSwapFace;
    bool isEnlarge = imageItemModel.isEnlarge;
    bool isSquare = imageItemModel.isSquare;
    bool isPublic = imageItemModel.isPublic;
    bool isInGallery = widget.isInGallery;

    if (isPublic && isInGallery) {
      finalMenuItems = widget.menuItemsPublic;
    } else if (isMJ) {
      finalMenuItems = widget.menuItemsMJ1;
      if (isUpScale) {
        var tempMenuList = isSquare ? widget.menuItemsMJ2Square : widget.menuItemsMJ2;
        finalMenuItems = tempMenuList;
        if (isEnlarge) {
          var newMenuItems = widget.menuItemsMJV6.sublist(0, 4);
          newMenuItems.addAll(tempMenuList.sublist(tempMenuList.length - 4));
          finalMenuItems = newMenuItems;
        }
      }
      if (isSwapFace) {
        finalMenuItems = widget.menuItemsSwapFaced;
      }
    } else {
      if (isCU) {
        finalMenuItems = widget.menuItemsCU;
      } else if (isFS) {
        finalMenuItems = widget.menuItemsFS;
      } else {
        finalMenuItems = widget.menuItems;
      }
    }
  }

  void refreshImage(int position, ImageItemModel imageData) {
    setState(() {
      imageItemModel = imageData;
      widget.imageItemModel = imageData;
      seed = imageData.seed;
      imageUrl = imageData.imageUrl;
      base64Image = imageData.base64Url;
      _updateFinalMenuItems();
    });
  }

  void toggleMenu() {
    FocusScope.of(context).unfocus();
    setState(() {
      isMenuVisible = !isMenuVisible;
      if (isMenuVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _calculateItemsPerRow(int totalItems, Size imageSize) {
    // 如果项目数小于等于3个，按实际数量显示
    if (totalItems <= 3) return totalItems;
    // 判断是否为小尺寸图片（例如高度小于320像素）且菜单项超过12个
    bool isSmallImage = imageSize.height < 320;
    bool isVerySmallImage = imageSize.height < 240;
    if (isVerySmallImage && totalItems > 12) {
      return 6; // 小图且多于12个菜单项时，每行显示5个
    } else if (isSmallImage && totalItems > 12) {
      return 5; // 小图且多于12个菜单项时，每行显示5个
    } else {
      return 4; // 其他情况保持4列布局
    }
  }

  Widget _buildOverlayMenu(Size imageSize, ChangeSettings settings) {
    int totalItems = finalMenuItems.length;
    int itemsPerRow = _calculateItemsPerRow(totalItems, imageSize);
    int numberOfRows = (totalItems / itemsPerRow).ceil();

    // 计算可用空间
    double availableWidth = imageSize.width * 0.95;
    double availableHeight = imageSize.height * 0.9;

    // 使用小间距
    double spacing = 1.0;

    // 计算单个项目的大小
    double itemSize = math.min((availableWidth - (itemsPerRow - 1) * spacing) / itemsPerRow,
        (availableHeight - (numberOfRows - 1) * spacing) / numberOfRows);

    return FadeTransition(
      opacity: _animation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: toggleMenu,
          child: Container(
            color: Colors.black.withAlpha(178),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: availableWidth,
                    maxHeight: availableHeight,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: itemsPerRow,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          totalItems,
                          (index) => _buildMenuItem(context, finalMenuItems[index], index, itemSize, settings),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 创建带样式的图标容器
  Widget _buildIconContainer(String assetName, double rotateAngle, ChangeSettings settings) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Transform.rotate(
        angle: rotateAngle * 3.1415926535897932 / 180, // 角度转换
        child: SvgPicture.asset('assets/images/$assetName',
            colorFilter: ColorFilter.mode(settings.getForegroundColor(), BlendMode.srcIn), semanticsLabel: assetName),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ItemModel item, int index, double itemSize, ChangeSettings settings) {
    double iconSize = itemSize * 0.45;
    double fontSize = math.max(9.0, itemSize * 0.11);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onMenuItemClick(
            index,
            base64Image,
            widget.position,
            item.position,
            item.title,
          );
          toggleMenu();
        },
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: itemSize,
          height: itemSize,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(itemSize * 0.03),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: _buildIconContainer(item.assetName, item.rotateAngle, settings),
                  ),
                  SizedBox(height: itemSize * 0.01),
                  Flexible(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    int drawEngine = imageItemModel.drawEngine;
    bool downloaded = imageItemModel.downloaded;
    String? drawProgress = imageItemModel.drawProgress;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: LayoutBuilder(builder: (context, constraints) {
        final Size imageSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image and click handler
              InkWell(
                onTap: () {
                  if (widget.showCheckbox) {
                    widget.onSelectionChanged(!widget.isSelected);
                  } else {
                    widget.onImageClick(widget.position);
                  }
                },
                onLongPress: () {
                  if (!widget.showCheckbox) {
                    widget.onSelectionChanged(true);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl == '' || drawProgress != '100%'
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black.withAlpha(128),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        drawProgress ?? '',
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : ExtendedImage.network(imageUrl, fit: BoxFit.cover)),
                    if (getRealDarkMode(settings))
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(76),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
              ),

              // Menu button
              Positioned(
                bottom: 5.0,
                right: 5.0,
                child: IconButton(
                  onPressed: toggleMenu,
                  icon: Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: getRealDarkMode(settings) ? settings.getSelectedBgColor() : Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/more_menu.svg',
                      colorFilter: ColorFilter.mode(settings.getForegroundColor(), BlendMode.srcIn),
                      semanticsLabel: '更多操作',
                    ),
                  ),
                ),
              ),

              // Draw engine label
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 4, bottom: 4, left: 6, right: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    drawEngine == 0
                        ? 'SD绘制'
                        : drawEngine == 1
                            ? 'MJ(1)绘制'
                            : drawEngine == 2
                                ? 'MJ绘制'
                                : drawEngine == 3
                                    ? 'CU绘制'
                                    : 'FS绘制',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // Seed value
              if (seed.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: seed));
                      if (mounted) {
                        showHint('种子值已复制到剪切板，可以复制到其他地方了', showType: 2);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 6, right: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        '种子值:  $seed',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

              // Downloaded indicator
              if (downloaded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 4, bottom: 4, left: 6, right: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '已保存',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              // Overlay menu
              if (isMenuVisible) _buildOverlayMenu(imageSize, settings),

              if (widget.showCheckbox)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (bool? value) {
                        if (value != null) {
                          widget.onSelectionChanged(value);
                        }
                      },
                      checkColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white, // 设置未选中时的边框颜色
                        width: 2.0, // 设置边框宽度
                      ),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return settings.getSelectedBgColor();
                        }
                        return Colors.transparent;
                      }),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
