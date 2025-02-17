import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/change_settings.dart';

class FloatingActionMenu extends StatefulWidget {
  const FloatingActionMenu({
    Key? key,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onToTop,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onToTop;

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu> with TickerProviderStateMixin {
  late AnimationController _menuAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;
  final List<OverlayEntry> _menuOverlayEntries = [];

  final double buttonSize = 50.0;
  final double menuItemSize = 50.0;
  final double menuRadius = 60.0;
  double posX = -25.0;
  double posY = 200.0;
  bool _isMenuOpen = false;
  bool _isOnLeftSide = true;
  bool _isDragging = false;
  final double _initialHideRatio = 0.5;
  final List<double> leftSideAngles = [-60.0, 0.0, 60.0];
  final List<double> rightSideAngles = [240.0, 180.0, 120.0];

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1 - _initialHideRatio,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          posX = -buttonSize * _initialHideRatio;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideMenuItems();
    _menuAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _showMenuItems();
        _slideAnimationController.animateTo(1.0);
        _menuAnimationController.forward();
      } else {
        _hideMenuItems();
        _menuAnimationController.reverse().then((_) {
          _slideAnimationController.animateTo(1 - _initialHideRatio);
        });
      }
    });
  }

  void _showMenuItems() {
    _hideMenuItems();

    // 获取按钮的全局位置
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    // 计算slideAnimation的当前偏移量
    double slideOffset = _isOnLeftSide ? -buttonSize * (1 - _slideAnimation.value) : buttonSize * (1 - _slideAnimation.value);

    // 计算按钮的中心点位置
    final double centerX = position.dx + slideOffset + buttonSize / 2;
    final double centerY = position.dy + buttonSize / 2;

    final menuItems = [
      (Icons.refresh, '刷新页面', widget.onRefresh),
      (Icons.keyboard_double_arrow_down_rounded, '加载更多', widget.onLoadMore),
      (Icons.vertical_align_top_rounded, '回到顶部', widget.onToTop),
    ];

    for (int i = 0; i < menuItems.length; i++) {
      final overlayEntry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: Listenable.merge([_menuAnimationController, _slideAnimation]),
          builder: (context, child) {
            // 实时计算slideAnimation的偏移量
            double currentSlideOffset =
                _isOnLeftSide ? -buttonSize * (1 - _slideAnimation.value) : buttonSize * (1 - _slideAnimation.value);

            final angles = _isOnLeftSide ? leftSideAngles : rightSideAngles;
            final angle = angles[i];
            final double rad = angle * math.pi / 180;

            // 计算菜单项位置
            final double itemX = math.cos(rad) * menuRadius * _menuAnimationController.value;
            final double itemY = math.sin(rad) * menuRadius * _menuAnimationController.value;

            // 计算最终位置，考虑到按钮的中心点和动画偏移
            return Positioned(
              left: centerX + itemX - menuItemSize / 2 + (currentSlideOffset - slideOffset),
              top: centerY + itemY - menuItemSize / 2,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    menuItems[i].$3();
                    _toggleMenu();
                  },
                  child: Container(
                    width: menuItemSize,
                    height: menuItemSize,
                    decoration: BoxDecoration(
                      color: context.read<ChangeSettings>().getBackgroundColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        menuItems[i].$1,
                        color: context.read<ChangeSettings>().getForegroundColor(),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      _menuOverlayEntries.add(overlayEntry);
      Overlay.of(context).insert(overlayEntry);
    }
  }

  void _hideMenuItems() {
    for (final entry in _menuOverlayEntries) {
      entry.remove();
    }
    _menuOverlayEntries.clear();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: posX,
      top: posY,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          double currentOffset =
              _isOnLeftSide ? -buttonSize * (1 - _slideAnimation.value) : buttonSize * (1 - _slideAnimation.value);

          return Transform.translate(
            offset: Offset(currentOffset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onPanStart: _isMenuOpen
                  ? null
                  : (details) {
                      setState(() {
                        _isDragging = true;
                        _slideAnimationController.animateTo(1.0);
                      });
                    },
              onPanUpdate: _isMenuOpen
                  ? null
                  : (details) {
                      if (_isDragging) {
                        setState(() {
                          posX = (posX + details.delta.dx).clamp(-buttonSize / 2, size.width - buttonSize / 2);
                          posY = (posY + details.delta.dy).clamp(0.0, size.height - buttonSize - 100);
                        });
                      }
                    },
              onPanEnd: _isMenuOpen
                  ? null
                  : (details) {
                      setState(() {
                        _isDragging = false;
                        final screenWidth = MediaQuery.of(context).size.width;
                        if (posX + buttonSize / 2 < screenWidth / 2) {
                          posX = -25;
                          _isOnLeftSide = true;
                        } else {
                          posX = screenWidth - buttonSize + 25;
                          _isOnLeftSide = false;
                        }
                        if (!_isMenuOpen) {
                          _slideAnimationController.animateTo(1 - _initialHideRatio);
                        }
                      });
                    },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: settings.getBackgroundColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _toggleMenu,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _menuAnimationController,
                        color: settings.getForegroundColor(),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
