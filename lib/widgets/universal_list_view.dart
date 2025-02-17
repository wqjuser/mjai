import 'package:flutter/material.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class UniversalListView<T> extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final List<T> items;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool isGridView;
  final int gridCrossAxisCount;
  final double gridChildAspectRatio;
  final bool hasMore;
  final WidgetBuilder? emptyBuilder;

  const UniversalListView({
    super.key,
    required this.itemBuilder,
    required this.items,
    this.onRefresh,
    this.onLoadMore,
    this.isGridView = false,
    this.gridCrossAxisCount = 2,
    this.gridChildAspectRatio = 1.0,
    this.hasMore = true,
    this.emptyBuilder,
  });

  @override
  State<UniversalListView> createState() => _UniversalListViewState<T>();
}

class _UniversalListViewState<T> extends State<UniversalListView<T>> {
  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  void _onRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshCompleted();
    }
  }

  void _onLoading() async {
    if (widget.onLoadMore != null && widget.hasMore) {
      await widget.onLoadMore!();
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  // 插入数据
  // void _insertItem(T item, int index) {
  //   setState(() {
  //     widget.items.insert(index, item);
  //   });
  // }

  // 删除数据
  // void _removeItem(int index) {
  //   setState(() {
  //     widget.items.removeAt(index);
  //   });
  // }

  // 更新数据
  // void _updateItem(T item, int index) {
  //   setState(() {
  //     widget.items[index] = item;
  //   });
  // }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.items.isEmpty) {
      content = widget.emptyBuilder != null
          ? widget.emptyBuilder!(context)
          : const Center(child: Text('暂无数据'));
    } else {
      Widget listView;
      if (widget.isGridView) {
        listView = GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridCrossAxisCount,
            childAspectRatio: widget.gridChildAspectRatio,
          ),
          itemBuilder: widget.itemBuilder,
          itemCount: widget.items.length,
        );
      } else {
        listView = ListView.builder(
          itemBuilder: widget.itemBuilder,
          itemCount: widget.items.length,
        );
      }
      content = SmartRefresher(
          controller: _refreshController,
          enablePullDown: widget.onRefresh != null,
          enablePullUp: widget.onLoadMore != null,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: listView);
    }
    return content;
  }
}
