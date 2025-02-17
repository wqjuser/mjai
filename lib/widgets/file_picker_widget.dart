import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

import '../utils/common_methods.dart';
import '../utils/file_picker_manager.dart';

class FilePickerWidget extends StatefulWidget {
  final int maxFiles;
  final Function(List<PlatformFile>) onFileChanged;
  final FileType fileType;
  final List<String>? allowedExtensions;

  const FilePickerWidget({
    required this.maxFiles,
    required this.onFileChanged,
    this.fileType = FileType.any,
    this.allowedExtensions,
    Key? key,
  }) : super(key: key);

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  List<PlatformFile>? _selectedFiles;

  // 选择文件
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePickerManager().pickFiles(
      type: widget.fileType,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: widget.maxFiles > 1, // 根据最大数量确定是否多选
    );

    if (result != null) {
      setState(() {
        if (widget.maxFiles == 1) {
          // 如果 maxFiles 为 1，则每次替换文件
          _selectedFiles = [result.files.first];
        } else {
          // 如果 maxFiles > 1，则保存多文件列表
          _selectedFiles = result.files;
        }
      });
      // 将更新后的文件列表传递给父组件
      widget.onFileChanged(_selectedFiles!);
    }
  }

  // 构建文件预览
  Widget _buildFileView(PlatformFile file) {
    return ListTile(
      leading: _isImage(file.path)
          ? Image.file(
              File(file.path!),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.insert_drive_file),
      title: Text(file.name),
      subtitle: Text(
        "大小: ${(file.size / 1024).toStringAsFixed(2)} KB",
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  // 判断是否是图片类型
  bool _isImage(String? path) {
    if (path == null) return false;
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      children: [
        ElevatedButton(
          style: getRealDarkMode(settings)
              ? ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()))
              : null,
          onPressed: _pickFiles,
          child: Text(
            widget.maxFiles == 1 ? "选择文件" : "选择文件（最多 ${widget.maxFiles} 个）",
            style: TextStyle(color: settings.getForegroundColor()),
          ),
        ),
        const SizedBox(height: 10),
        _selectedFiles == null
            ? Center(child: Text("未选择任何文件", style: TextStyle(color: settings.getForegroundColor())))
            : Expanded(
                child: ListView.builder(
                  itemCount: _selectedFiles!.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles![index];
                    return _buildFileView(file);
                  },
                ),
              ),
      ],
    );
  }
}
