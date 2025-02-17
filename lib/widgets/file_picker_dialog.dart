import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import '../utils/file_picker_manager.dart';

class FilePickerDialog extends StatefulWidget {
  final Function(List<PlatformFile>, String updateInfo) onConfirm;
  final int maxFiles;
  final String? title;

  const FilePickerDialog({
    required this.onConfirm,
    this.maxFiles = 1, // 默认最大文件数改为 1
    this.title = '上传新版本',
    Key? key,
  }) : super(key: key);

  @override
  State<FilePickerDialog> createState() => _FilePickerDialogState();
}

class _FilePickerDialogState extends State<FilePickerDialog> {
  List<PlatformFile> selectedFiles = [];
  final TextEditingController _updateInfoController = TextEditingController(text: '');
  String? _error;

  @override
  void dispose() {
    _updateInfoController.dispose();
    super.dispose();
  }

  // 允许的文件扩展名
  static const allowedExtensions = ['exe', 'dmg'];

  bool _isValidFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    return allowedExtensions.contains(extension);
  }

  void _handleFileSelection(List<PlatformFile> files) {
    // 验证文件类型
    final invalidFiles = files.where((file) => !_isValidFile(file)).toList();
    if (invalidFiles.isNotEmpty) {
      setState(() {
        _error = '只支持 .exe 或 .dmg 格式的安装包';
        selectedFiles = [];
      });
      return;
    }

    setState(() {
      _error = null;
      selectedFiles = files;
    });
  }

  // 选择文件
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePickerManager().pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: widget.maxFiles > 1, // 根据最大数量确定是否多选
    );

    if (result != null) {
      setState(() {
        if (widget.maxFiles == 1) {
          // 如果 maxFiles 为 1，则每次替换文件
          _handleFileSelection([result.files.first]);
        } else {
          // 如果 maxFiles > 1，则保存多文件列表
          _handleFileSelection(result.files);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Dialog(
      backgroundColor: settings.getBackgroundColor(),
      elevation: 0,
      child: Container(
        height: selectedFiles.isNotEmpty ? 480 : 400,
        width: 400,
        decoration: BoxDecoration(
          color: settings.getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(settings),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Picker Area
                    _buildFilePickerArea(settings),

                    const SizedBox(height: 24),

                    // Update Info Input
                    _buildUpdateInfoInput(settings),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(settings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChangeSettings settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.file_upload,
            color: settings.getForegroundColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.title ?? '上传新版本',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: settings.getForegroundColor(),
              fontSize: 20,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: settings.getForegroundColor(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerArea(ChangeSettings settings) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error != null ? Colors.red : settings.getForegroundColor(),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ElevatedButton(
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                    onPressed: _pickFiles,
                    child: Text(
                      widget.maxFiles == 1 ? "选择文件" : "选择文件（最多 ${widget.maxFiles} 个）",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        )),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '支持的格式：Windows (.exe) 或 macOS (.dmg) 安装包',
                    style: TextStyle(color: settings.getHintTextColor(), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: settings.getBackgroundColor(),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedFiles.map((file) => _buildFileItem(file, settings)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(PlatformFile file, ChangeSettings settings) {
    final isExe = file.extension?.toLowerCase() == 'exe';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isExe ? Icons.laptop_windows : Icons.laptop_mac,
            size: 20,
            color: settings.getForegroundColor(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(color: settings.getForegroundColor(), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isExe ? 'Windows 安装包' : 'macOS 安装包',
                  style: TextStyle(color: settings.getForegroundColor(), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatFileSize(file.size),
            style: TextStyle(color: settings.getForegroundColor(), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateInfoInput(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '更新说明',
          style: TextStyle(
            color: settings.getForegroundColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _updateInfoController,
          maxLines: 5,
          minLines: 3,
          style: TextStyle(color: settings.getForegroundColor(), fontSize: 14),
          decoration: InputDecoration(
            hintText: '请输入本次更新的主要内容',
            hintStyle: TextStyle(color: settings.getHintTextColor()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: settings.getForegroundColor(),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: settings.getSelectedBgColor(),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ChangeSettings settings) {
    bool canSubmit = selectedFiles.isNotEmpty && _updateInfoController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              '取消',
              style: TextStyle(
                color: settings.getForegroundColor(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder(
              valueListenable: _updateInfoController,
              builder: (context, value, child) {
                canSubmit = selectedFiles.isNotEmpty && value.text.trim().isNotEmpty;
                return FilledButton(
                  onPressed: canSubmit
                      ? () {
                          widget.onConfirm(selectedFiles, value.text.trim());
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: canSubmit ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(128),
                  ),
                  child: Text(
                    '确定',
                    style: TextStyle(
                      color: canSubmit ? settings.getCardTextColor() : Colors.grey.withAlpha(128),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
