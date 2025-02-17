import 'package:flutter/material.dart';

class DraggableWidget<T> extends StatelessWidget {
  final T data;
  final Widget child;
  final Function(int before, int after) onDragFinish;
  final int index;
  final List<T> items;

  const DraggableWidget({
    Key? key,
    required this.data,
    required this.child,
    required this.onDragFinish,
    required this.index,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Object>(
      data: data,
      axis: Axis.vertical,
      feedback: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
          child: child,
        ),
      ),
      childWhenDragging: Container(),
      child: DragTarget(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          final dynamic receivedItemData = details.data;
          // 在这里进行类型检查和转换，确保安全性
          if (receivedItemData is T && receivedItemData != data) {
            final int beforeIndex = items.indexOf(receivedItemData);
            final int afterIndex = index;
            onDragFinish(beforeIndex, afterIndex);
          }
        },
        builder: (context, candidateData, rejectedData) => child,
      ),
    );
  }
}
