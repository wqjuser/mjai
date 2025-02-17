import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

typedef OnContentChanged = Function(String newContent);

class FileContentViewer extends StatefulWidget {
  final String fileContent;
  final String fileName;
  final bool isEditable;
  final OnContentChanged? onContentChanged;

  const FileContentViewer({
    super.key,
    required this.fileContent,
    required this.fileName,
    this.isEditable = false,
    this.onContentChanged,
  });

  @override
  State<FileContentViewer> createState() => _FileContentViewerState();
}

class _TextLine {
  String text;
  bool isEditing;

  _TextLine(this.text, {this.isEditing = false});

  _TextLine copyWith({String? text, bool? isEditing}) {
    return _TextLine(
      text ?? this.text,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class _FileContentViewerState extends State<FileContentViewer> {
  late List<_TextLine> _lines;
  late ScrollController _dialogScrollController;
  late ScrollController _fullscreenScrollController;

  @override
  void initState() {
    super.initState();
    _dialogScrollController = ScrollController();
    _fullscreenScrollController = ScrollController();
    _initializeContent();
  }

  void _initializeContent() {
    _lines = widget.fileContent.split('\n').asMap().entries.map((e) => _TextLine(e.value)).toList();
  }

  @override
  void dispose() {
    _dialogScrollController.dispose();
    _fullscreenScrollController.dispose();
    super.dispose();
  }

  void _updateLineNumbers() {
    for (var i = 0; i < _lines.length; i++) {
      // _lines[i].lineNumber = i + 1;
    }
  }

  void _onLinesChanged(List<_TextLine> newLines) {
    if (mounted) {
      setState(() {
        _lines = newLines;
        _updateLineNumbers();
      });
      widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
    }
  }

  Future<void> _showFullScreen(BuildContext context, ChangeSettings settings) async {
    final currentScrollPosition = _dialogScrollController.hasClients ? _dialogScrollController.position.pixels : 0.0;

    final result = await Navigator.of(context).push<List<_TextLine>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenViewer(
          lines: List<_TextLine>.from(_lines),
          fileName: widget.fileName,
          isEditable: widget.isEditable,
          initialScrollOffset: currentScrollPosition,
          onContentChanged: widget.onContentChanged,
          settings: settings,
        ),
      ),
    );

    if (result != null) {
      _onLinesChanged(result);
    }
  }

  Widget _buildLine(BuildContext context, int index, ChangeSettings settings) {
    final line = _lines[index];
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              line.text,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 16.0,
                fontFamily: 'Courier',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      backgroundColor: settings.getBackgroundColor(),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: settings.getForegroundColor(),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isEditable)
                  IconButton(
                    icon: Icon(Icons.edit, color: settings.getForegroundColor()),
                    onPressed: () => _showFullScreen(context, settings),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 1,
              color: settings.getForegroundColor().withAlpha(25),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                controller: _dialogScrollController,
                itemCount: _lines.length,
                itemBuilder: (context, index) => _buildLine(context, index, settings),
                cacheExtent: 800.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  final List<_TextLine> lines;
  final String fileName;
  final bool isEditable;
  final double initialScrollOffset;
  final OnContentChanged? onContentChanged;
  final ChangeSettings settings;

  const _FullScreenViewer({
    Key? key,
    required this.lines,
    required this.fileName,
    required this.isEditable,
    required this.initialScrollOffset,
    required this.settings,
    this.onContentChanged,
  }) : super(key: key);

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

// 用于带索引的迭代器扩展
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}

class _EditOperation {
  final List<_TextLine> lines;
  final int cursorIndex;
  final int cursorPosition;

  _EditOperation(this.lines, this.cursorIndex, this.cursorPosition);
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late ScrollController _scrollController;
  late List<_TextLine> _lines;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  bool _isUpdatingLines = false;

  // 撤销历史
  final List<_EditOperation> _undoHistory = [];
  int _currentHistoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _lines = widget.lines.map((line) => _TextLine(line.text)).toList();
    // 保存初始状态
    _saveState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }

  void _saveState() {
    if (_isUpdatingLines) return;

    // 获取当前光标位置
    int cursorIndex = 0;
    int cursorPosition = 0;
    for (var entry in _controllers.entries) {
      if (_focusNodes[entry.key]?.hasFocus ?? false) {
        cursorIndex = entry.key;
        cursorPosition = entry.value.selection.baseOffset;
        break;
      }
    }

    // 创建当前状态的深拷贝
    final stateCopy = _lines.map((line) => _TextLine(line.text)).toList();

    // 移除当前位置之后的历史记录
    if (_currentHistoryIndex < _undoHistory.length - 1) {
      _undoHistory.removeRange(_currentHistoryIndex + 1, _undoHistory.length);
    }

    // 添加新状态到历史记录
    _undoHistory.add(_EditOperation(stateCopy, cursorIndex, cursorPosition));
    _currentHistoryIndex++;

    // 限制历史记录大小
    if (_undoHistory.length > 100) {
      _undoHistory.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  void _undo() {
    if (_currentHistoryIndex > 0) {
      _isUpdatingLines = true;
      _currentHistoryIndex--;

      final previousState = _undoHistory[_currentHistoryIndex];
      setState(() {
        _lines = previousState.lines.map((line) => _TextLine(line.text)).toList();
        _controllers.clear();
        _focusNodes.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 恢复光标位置
            final controller = _getController(previousState.cursorIndex, _lines[previousState.cursorIndex].text);
            final focusNode = _getFocusNode(previousState.cursorIndex);

            focusNode.requestFocus();
            controller.selection = TextSelection.collapsed(offset: previousState.cursorPosition);
          }
          _isUpdatingLines = false;
          widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
        });
      });
    }
  }

  void _handleLineChange(int index, String newText) {
    if (mounted && !_isUpdatingLines) {
      setState(() {
        _lines[index].text = newText;
        _saveState();
      });
      widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
    }
  }

  // 处理光标移动到上一行
  void _moveCursorToPreviousLine(int currentIndex) {
    if (currentIndex > 0) {
      final targetIndex = currentIndex - 1;
      final targetController = _getController(targetIndex, _lines[targetIndex].text);
      final targetFocusNode = _getFocusNode(targetIndex);

      targetFocusNode.requestFocus();
      targetController.selection = TextSelection.collapsed(offset: targetController.text.length);
    }
  }

  // 处理光标移动到下一行
  void _moveCursorToNextLine(int currentIndex) {
    if (currentIndex < _lines.length - 1) {
      final targetIndex = currentIndex + 1;
      final targetController = _getController(targetIndex, _lines[targetIndex].text);
      final targetFocusNode = _getFocusNode(targetIndex);

      targetFocusNode.requestFocus();
      targetController.selection = const TextSelection.collapsed(offset: 0);
    }
  }

  void _handleKeyPress(KeyEvent event, int index, TextEditingController controller) {
    if (event is KeyDownEvent && !_isUpdatingLines) {
      // 处理撤销快捷键
      if ((event.logicalKey == LogicalKeyboardKey.keyZ) && HardwareKeyboard.instance.isControlPressed) {
        _undo();
        return;
      }

      // 处理回车键
      if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
        _isUpdatingLines = true;

        final currentText = controller.text;
        final cursorPosition = controller.selection.baseOffset;
        final beforeCursor = cursorPosition >= 0 ? currentText.substring(0, cursorPosition) : currentText;
        final afterCursor = cursorPosition >= 0 ? currentText.substring(cursorPosition) : '';

        setState(() {
          // 更新当前行
          _lines[index] = _TextLine(beforeCursor);

          // 插入新行
          _lines.insert(index + 1, _TextLine(afterCursor));

          // 清理控制器缓存
          _controllers.clear();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final newController = _getController(index + 1, afterCursor);
              final newFocusNode = _getFocusNode(index + 1);

              newFocusNode.requestFocus();
              newController.value = TextEditingValue(
                text: afterCursor,
                selection: const TextSelection.collapsed(offset: 0),
              );

              _isUpdatingLines = false;
              _saveState();
            }
            widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
          });
        });
      }
      // 处理删除键
      else if ((event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.delete) &&
          controller.text.isEmpty &&
          _lines.length > 1) {
        _isUpdatingLines = true;
        setState(() {
          final targetIndex = index > 0 ? index - 1 : index;
          final targetText = _lines[targetIndex].text;

          // 删除当前空行
          _lines.removeAt(index);

          // 清理控制器缓存
          _controllers.clear();
          _focusNodes.clear();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final targetController = _getController(targetIndex, targetText);
              final targetFocusNode = _getFocusNode(targetIndex);

              targetFocusNode.requestFocus();
              targetController.value = TextEditingValue(
                text: targetText,
                selection: TextSelection.collapsed(offset: targetText.length),
              );

              _isUpdatingLines = false;
              _saveState();
            }
            widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
          });
        });
      }
      // 处理上下方向键
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveCursorToPreviousLine(index);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveCursorToNextLine(index);
      }
    }
  }

  TextEditingController _getController(int index, String text) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(text: text);
    }
    return _controllers[index]!;
  }

  FocusNode _getFocusNode(int index) {
    if (!_focusNodes.containsKey(index)) {
      _focusNodes[index] = FocusNode();
    }
    return _focusNodes[index]!;
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否为 macOS 平台
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final topPadding = isMacOS ? 28.0 : 0.0; // macOS 下添加额外的顶部间距

    return Scaffold(
      backgroundColor: widget.settings.getBackgroundColor(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + topPadding),
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          color: widget.settings.getBackgroundColor(),
          child: AppBar(
            backgroundColor: widget.settings.getBackgroundColor(),
            title: Text(
              widget.fileName,
              style: TextStyle(color: widget.settings.getForegroundColor()),
            ),
            iconTheme: IconThemeData(color: widget.settings.getForegroundColor()),
            leading: IconButton(
              icon: Icon(Icons.close, color: widget.settings.getForegroundColor()),
              onPressed: () => Navigator.of(context).pop(_lines),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.check, color: widget.settings.getForegroundColor()),
                onPressed: () {
                  widget.onContentChanged?.call(_lines.map((l) => l.text).join('\n'));
                  Navigator.of(context).pop(_lines);
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _lines.length,
          itemBuilder: _buildLine,
          cacheExtent: 800.0,
        ),
      ),
    );
  }

  Widget _buildLine(BuildContext context, int index) {
    final line = _lines[index];
    final textStyle = TextStyle(
      color: widget.settings.getForegroundColor(),
      fontSize: 16.0,
      fontFamily: 'Courier',
      height: 1.5,
    );

    final controller = _getController(index, line.text);
    final focusNode = _getFocusNode(index);

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: KeyboardListener(
        focusNode: FocusNode(), // 分离焦点节点
        onKeyEvent: (event) => _handleKeyPress(event, index, controller),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          maxLines: null,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 4),
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) => _handleLineChange(index, value),
        ),
      ),
    );
  }
}
