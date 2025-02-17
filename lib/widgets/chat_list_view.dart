import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tuitu/utils/common_methods.dart';

class ScrollState {
  final bool isAtBottom;
  final bool userScrolledUp;

  ScrollState({
    required this.isAtBottom,
    required this.userScrolledUp,
  });
}

class ChatListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool autoScroll;
  final EdgeInsets padding;
  final ValueChanged<ScrollState>? onScrollStateChanged;

  const ChatListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.autoScroll = true,
    this.padding = EdgeInsets.zero,
    this.onScrollStateChanged,
  }) : super(key: key);

  @override
  State<ChatListView> createState() => ChatListViewState();
}

class ChatListViewState extends State<ChatListView> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLayout = true;
  bool _needsScroll = false;
  int _previousItemCount = 0;
  bool _userScrolled = false;
  bool _isNearBottom = true;
  double _lastScrollOffset = 0.0;
  bool _isScrollingProgrammatically = false;
  bool _isScrollingScheduled = false;
  int _lastScrollTime = 0;
  Ticker? _ticker;
  double? _lastMaxScrollExtent;

  static const double _scrollThreshold = 50.0;
  static const int _minScrollInterval = 16;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _ticker = createTicker(_onTick);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.autoScroll) {
        _scheduleScroll();
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (_needsScroll && !_isScrollingScheduled) {
      _performScroll();
    }
  }

  bool isScrolledToBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return maxScroll - currentScroll <= _scrollThreshold;
  }

  void scrollToBottom() {
    _userScrolled = false;
    _scheduleScroll();
  }

  void _scheduleScroll() {
    if (!_ticker!.isTicking) {
      _ticker!.start();
    }
    _needsScroll = true;
  }

  void _notifyScrollStateChanged() {
    widget.onScrollStateChanged?.call(ScrollState(
      isAtBottom: _isNearBottom,
      userScrolledUp: _userScrolled,
    ));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final currentScroll = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final isNearBottom = maxScroll - currentScroll <= _scrollThreshold;
    bool stateChanged = false;

    // 检测列表内容高度是否发生变化
    if (_lastMaxScrollExtent != null && _lastMaxScrollExtent != maxScroll) {
      if (widget.autoScroll && (_isNearBottom || !_userScrolled)) {
        _scheduleScroll();
      }
    }
    _lastMaxScrollExtent = maxScroll;

    if (!_isScrollingProgrammatically) {
      if (currentScroll > _lastScrollOffset && !isNearBottom && !_userScrolled) {
        _userScrolled = false;
        stateChanged = true;
      } else if (currentScroll < _lastScrollOffset && !isNearBottom) {
        _userScrolled = true;
        stateChanged = true;
      }
    }

    if (_isNearBottom != isNearBottom) {
      _isNearBottom = isNearBottom;
      if (isNearBottom) {
        _userScrolled = false;
      }
      stateChanged = true;
    }

    if (stateChanged) {
      _notifyScrollStateChanged();
    }

    _lastScrollOffset = currentScroll;
  }

  @override
  void didUpdateWidget(ChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.itemCount != _previousItemCount || widget.itemCount == oldWidget.itemCount) &&
        widget.autoScroll &&
        (_isNearBottom || !_userScrolled)) {
      _scheduleScroll();
    }
    _previousItemCount = widget.itemCount;
  }

  void _performScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastScrollTime < _minScrollInterval) {
      return;
    }
    _lastScrollTime = currentTime;
    _isScrollingScheduled = true;

    try {
      _isScrollingProgrammatically = true;
      final maxScroll = _scrollController.position.maxScrollExtent;
      // 使用非常短的动画时间
      _scrollController
          .animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 5),
        curve: Curves.linear,
      )
          .whenComplete(() {
        _isScrollingProgrammatically = false;
        _needsScroll = false;
        _isScrollingScheduled = false;
      });
      _isScrollingProgrammatically = false;
      _needsScroll = false;
      _isScrollingScheduled = false;
    } catch (e) {
      _isScrollingProgrammatically = false;
      _isScrollingScheduled = false;
      commonPrint('滚动错误: $e');
    }

    if (!_needsScroll && _ticker!.isTicking) {
      _ticker!.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLayout) {
      _isFirstLayout = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyScrollStateChanged();
      });
    }

    return ListView.builder(
      padding: widget.padding,
      controller: _scrollController,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
