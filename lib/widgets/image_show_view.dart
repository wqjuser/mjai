import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/image_show_item.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../json_models/item_model.dart';

class ImageView extends StatefulWidget {
  final List<ImageItemModel> imageBase64List;
  final BuildContext context;
  final Function(int position)? onUpScale;
  final Function(int position)? onImageClick;
  final Function(int position)? onUpScaleRepair;
  final Function(int position, int optionPosition, String optionName)? furtherOperations;
  final bool isInGallery;
  final Function(List<int> selectedIndexes) onSelectionChange; // 新增选中回调

  const ImageView({
    super.key,
    required this.imageBase64List,
    required this.context,
    this.onUpScale,
    this.onUpScaleRepair,
    this.onImageClick,
    this.furtherOperations,
    this.isInGallery = false,
    required this.onSelectionChange,
  });

  @override
  State<StatefulWidget> createState() => ImageViewState();
}

class ImageViewState extends State<ImageView> {
  late List<ItemModel> menuItems;
  late List<ItemModel> menuItemsPublic;
  late List<ItemModel> menuItemsSwapFaced;
  late List<ItemModel> menuItemsCU;
  late List<ItemModel> menuItemsFS;
  late List<ItemModel> menuItemsMJ1;
  late List<ItemModel> menuItemsMJV6;
  late List<ItemModel> menuItemsMJ2;
  late List<ItemModel> menuItemsMJ2Square;
  late List<ItemModel> finalMenuItems;
  late ImageShowItem imageShowItem;
  String drawEngineText = 'SD绘制';
  var seed = '';
  List<GlobalKey<ImageShowItemState>> itemKeys = [];
  List<ImageShowItem> items = [];

  // 在状态类中维护选择模式相关的状态
  bool _isSelectionMode = false;
  final Map<int, bool> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
  }

  // 处理选择变化
  void _handleSelectionChanged(int index, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems[index] = true;
      } else {
        _selectedItems.remove(index);
      }

      _isSelectionMode = _selectedItems.isNotEmpty;

      // 通知父组件选中项变化
      widget.onSelectionChange(_selectedItems.keys.toList());
    });
  }

  // 退出选择模式
  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
      widget.onSelectionChange([]);
    });
  }

  void _initializeMenuItems() {
    menuItems = [
      _createMenuItem('图片高清', 'up_scale.svg', 0),
      _createMenuItem('图片重绘', 'up_scale_repair.svg', 1),
      _createMenuItem('获取种子', 'seed.svg', 10, rotateAngle: 180),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsSwapFaced = [
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsCU = [
      _createMenuItem('图片高清', 'up_scale.svg', 0),
      _createMenuItem('图片重绘', 'up_scale_repair.svg', 1),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsFS = [
      _createMenuItem('图片变换', 'variation.svg', 0),
      _createMenuItem('图片重绘', 'up_scale_repair.svg', 1),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsMJ1 = [
      _createMenuItem('图片高清', 'up_scale.svg', 0),
      _createMenuItem('图片变换', 'variation.svg', 1),
      _createMenuItem('获取种子', 'seed.svg', 10, rotateAngle: 180),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('重新生成', 're_draw.svg', 4),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsMJV6 = [
      _createMenuItem('重做精致', 'up_scale.svg', 0),
      _createMenuItem('重做创造', 'up_scale.svg', 1),
      _createMenuItem('轻微变换', 'variation.svg', 2, rotateAngle: 360),
      _createMenuItem('强烈变换', 'variation.svg', 3),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsMJ2 = [
      _createMenuItem('精致高档', 'upscale.svg', 0),
      _createMenuItem('创意高档', 'upscale.svg', 1),
      _createMenuItem('轻微变换', 'variation.svg', 2),
      _createMenuItem('高变换', 'variation.svg', 3),
      _createMenuItem('局部重绘', 'redraw_part.svg', 12),
      _createMenuItem('缩小2.0倍', 'zoom.svg', 5),
      _createMenuItem('缩小1.5倍', 'zoom.svg', 6),
      _createMenuItem('自选缩放', 'zoom.svg', 11),
      _createMenuItem('变为方形', 'squaring.svg', 20),
      _createMenuItem('焦点左移', 'arrow_up.svg', 8, rotateAngle: -90),
      _createMenuItem('焦点右移', 'arrow_up.svg', 9, rotateAngle: 90),
      _createMenuItem('焦点上移', 'arrow_up.svg', 10),
      _createMenuItem('焦点下移', 'arrow_up.svg', 11, rotateAngle: 180),
      _createMenuItem('换脸', 'swap_face.svg', 15, rotateAngle: 360),
      _createMenuItem('获取种子', 'seed.svg', 10, rotateAngle: 180),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsMJ2Square = [
      _createMenuItem('精致高档', 'upscale.svg', 0),
      _createMenuItem('创意高档', 'upscale.svg', 1),
      _createMenuItem('轻微变换', 'variation.svg', 2),
      _createMenuItem('强烈变换', 'variation.svg', 3),
      _createMenuItem('局部重绘', 'redraw_part.svg', 12),
      _createMenuItem('缩小2.0倍', 'zoom.svg', 5),
      _createMenuItem('缩小1.5倍', 'zoom.svg', 6),
      _createMenuItem('自选缩放', 'zoom.svg', 11),
      _createMenuItem('焦点左移', 'arrow_up.svg', 8, rotateAngle: -90),
      _createMenuItem('焦点右移', 'arrow_up.svg', 9, rotateAngle: 90),
      _createMenuItem('焦点上移', 'arrow_up.svg', 10),
      _createMenuItem('焦点下移', 'arrow_up.svg', 11, rotateAngle: 180),
      _createMenuItem('换脸', 'swap_face.svg', 15, rotateAngle: 360),
      _createMenuItem('获取种子', 'seed.svg', 10, rotateAngle: 180),
      _createMenuItem('保存图片', 'save.svg', 2),
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
      _createMenuItem('删除图片', 'delete.svg', 30),
    ];

    menuItemsPublic = [
      _createMenuItem('复制Tag', 'copy_prompt.svg', 22),
    ];

    finalMenuItems = [];
  }

  // 工厂方法：创建菜单项
  ItemModel _createMenuItem(String label, String assetName, int id, {double rotateAngle = 0}) {
    return ItemModel(label, assetName, id, rotateAngle: rotateAngle);
  }

  void _onMenuTap(int position, String base64Image, int imagePosition, int optionId, String optionName) async {
    switch (optionId) {
      case 0:
        if (optionName == '强烈变换' || optionName.contains('高档') || optionName.contains('重做')) {
          if (widget.furtherOperations != null) {
            widget.furtherOperations!(imagePosition, optionId, optionName);
          }
        } else {
          if (widget.onUpScale != null) {
            widget.onUpScale!(imagePosition);
          }
        }
        break;
      case 1:
        if (optionName == '轻微变换' || optionName.contains('高档') || optionName.contains('重做')) {
          if (widget.furtherOperations != null) {
            widget.furtherOperations!(imagePosition, optionId, optionName);
          }
        } else {
          if (widget.onUpScaleRepair != null) {
            widget.onUpScaleRepair!(imagePosition);
          }
        }
        break;
      case 2:
        if (optionName != '保存图片') {
          if (widget.furtherOperations != null) {
            widget.furtherOperations!(imagePosition, optionId, optionName);
          }
        } else {
          if (!widget.imageBase64List[imagePosition].downloaded) {
            String imageUrl = widget.imageBase64List[imagePosition].imageUrl;
            if (mounted) {
              await saveImageToDirectory(base64Image, context, imageUrl: imageUrl);
            }
            widget.imageBase64List[imagePosition].downloaded = true;
            refreshImage(imagePosition, widget.imageBase64List[imagePosition]);
            //TODO 这里要注意是否要在数据库保存已下载状态 或许可以在设置页面加一个配置
            // var imageKey = widget.imageBase64List[imagePosition].imageKey!;
            // var imageInfo = jsonEncode(widget.imageBase64List[imagePosition].toJson());
            // await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
          } else {
            if (mounted) {
              showHint('此图片已保存');
            }
          }
        }
        break;
      default:
        if (widget.furtherOperations != null) {
          widget.furtherOperations!(imagePosition, optionId, optionName);
        }
        break;
    }
  }

  void _onImageClick(int imagePosition) async {
    widget.onImageClick!(imagePosition);
  }

  void refreshImage(int position, ImageItemModel imageData) {
    itemKeys[position].currentState?.refreshImage(position, imageData);
    widget.imageBase64List[position] = imageData;
    setState(() {});
  }

  void insertImageData(List<ImageItemModel> imageData, int lastImageNum, int currentImageNum, int drawEngine) {
    setState(() {
      widget.imageBase64List.insertAll(lastImageNum, imageData);
    });
  }

  void clearAll() {
    setState(() {
      widget.imageBase64List.clear();
    });
  }

  // 新增批量删除方法
  void deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    setState(() {
      // 将选中的索引排序并反转,这样从后往前删除就不会影响前面的索引
      final indexesToDelete = _selectedItems.keys.toList()
        ..sort()
        ..reversed;
      final reversedIndexes = indexesToDelete.reversed;
      // 从后往前删除
      for (final index in reversedIndexes) {
        widget.imageBase64List.removeAt(index);
      }

      // 清空选择状态
      _selectedItems.clear();
      _isSelectionMode = false;

      // 通知父组件选中状态变化
      widget.onSelectionChange([]);
    });
  }

  // 修改现有删除单个项目的方法
  void deleteCurrent(int position) {
    setState(() {
      widget.imageBase64List.removeAt(position);
      // 如果删除的是已选中的项目,需要更新选中状态
      if (_selectedItems.containsKey(position)) {
        _selectedItems.remove(position);
        // 删除后需要更新所有大于该位置的索引
        final newSelectedItems = <int, bool>{};
        _selectedItems.forEach((key, value) {
          if (key > position) {
            newSelectedItems[key - 1] = value;
          } else {
            newSelectedItems[key] = value;
          }
        });
        _selectedItems.clear();
        _selectedItems.addAll(newSelectedItems);
      }
      _isSelectionMode = _selectedItems.isNotEmpty;
      widget.onSelectionChange(_selectedItems.keys.toList());
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int count = (screenWidth / 320).floor(); // 假设每个图片最小宽度为320
    Orientation orientation = MediaQuery.of(context).orientation;
    if (Platform.isWindows || Platform.isMacOS) {
      return count.clamp(4, 10);
    } else {
      return orientation == Orientation.landscape ? 2 : 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    int imageCount = widget.imageBase64List.length;
    itemKeys.clear();
    for (int i = 0; i < imageCount; i++) {
      GlobalKey<ImageShowItemState> itemKey = GlobalKey<ImageShowItemState>();
      itemKeys.add(itemKey);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _calculateCrossAxisCount(context);
        double itemWidth = constraints.maxWidth / crossAxisCount;

        return MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          itemCount: imageCount,
          itemBuilder: (context, index) {
            final imageItem = widget.imageBase64List[index];
            return SizedBox(
              width: itemWidth,
              child: AspectRatioMaintainer(
                imageUrl: imageItem.imageUrl,
                isLoading: imageItem.imageUrl.isEmpty,
                imageKey: imageItem.imageKey ?? '',
                imageData: imageItem,
                builder: (context, aspectRatio) {
                  return _buildSingleImage(
                    widget.imageBase64List[index].base64Url,
                    index,
                    itemKeys[index],
                    aspectRatio,
                  );
                },
                ratio: widget.imageBase64List[index].imageAspectRatio,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSingleImage(String base64Image, int position, GlobalKey<ImageShowItemState> itemKey, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ImageShowItem(
        key: itemKey,
        menuItems: menuItems,
        menuItemsPublic: menuItemsPublic,
        menuItemsSwapFaced: menuItemsSwapFaced,
        menuItemsCU: menuItemsCU,
        menuItemsFS: menuItemsFS,
        menuItemsMJ1: menuItemsMJ1,
        menuItemsMJV6: menuItemsMJV6,
        menuItemsMJ2: menuItemsMJ2,
        menuItemsMJ2Square: menuItemsMJ2Square,
        finalMenuItems: finalMenuItems,
        imageItemModel: widget.imageBase64List[position],
        imageUrl: widget.imageBase64List[position].imageUrl,
        base64Image: base64Image,
        onMenuItemClick: _onMenuTap,
        onImageClick: _onImageClick,
        position: position,
        isInGallery: widget.isInGallery,
        showCheckbox: _isSelectionMode,
        isSelected: _selectedItems.containsKey(position),
        onSelectionChanged: (isSelected) => _handleSelectionChanged(position, isSelected),
      ),
    );
  }
}

class AspectRatioMaintainer extends StatefulWidget {
  final String imageUrl;
  final bool isLoading;
  final Widget Function(BuildContext context, double aspectRatio) builder;
  final double? ratio;
  final String imageKey;
  final ImageItemModel imageData;

  const AspectRatioMaintainer({
    super.key,
    required this.imageUrl,
    required this.builder,
    required this.imageKey,
    required this.imageData,
    this.isLoading = false,
    this.ratio,
  });

  @override
  State<AspectRatioMaintainer> createState() => _AspectRatioMaintainerState();
}

class _AspectRatioMaintainerState extends State<AspectRatioMaintainer> {
  double? _aspectRatio;

  bool get _hasValidUrl => widget.imageUrl.isNotEmpty;
  String? _lastLoadedUrl;

  @override
  void initState() {
    super.initState();
    _initAspectRatio();
  }

  void _initAspectRatio() {
    if (widget.ratio != null) {
      // 如果提供了有效的比例，直接使用
      setState(() {
        _aspectRatio = widget.ratio;
      });
    } else if (_hasValidUrl) {
      // 如果没有提供比例但有有效URL，加载图片获取比例
      _loadImage();
    } else {
      // 如果既没有比例也没有URL，使用默认值
      setState(() {
        _aspectRatio = 1.0;
      });
    }
  }

  @override
  void didUpdateWidget(AspectRatioMaintainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.ratio != oldWidget.ratio) {
      // ratio 发生变化时重新初始化
      _initAspectRatio();
    } else if (widget.ratio == null &&
        (widget.imageUrl != oldWidget.imageUrl || _lastLoadedUrl != widget.imageUrl) &&
        _hasValidUrl) {
      // 只有在没有提供 ratio 且 URL 变化时才加载图片
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.isLoading || !_hasValidUrl) return;
    try {
      final ImageProvider provider = NetworkImage(widget.imageUrl);
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final Completer<void> completer = Completer<void>();

      final ImageStreamListener listener = ImageStreamListener(
        (ImageInfo imageInfo, bool synchronousCall) {
          if (!mounted) return;

          final double width = imageInfo.image.width.toDouble();
          final double height = imageInfo.image.height.toDouble();

          setState(() {
            _aspectRatio = width / height;
            _lastLoadedUrl = widget.imageUrl;
          });
          completer.complete();
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!mounted) return;
          setState(() {
            _aspectRatio = 1.0;
          });
          completer.completeError(exception, stackTrace);
        },
      );

      stream.addListener(listener);
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) {
            setState(() {
              _aspectRatio = 1.0;
            });
          }
        },
      );
      if (mounted) {
        stream.removeListener(listener);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aspectRatio = 1.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _aspectRatio ?? 1.0);
  }
}
