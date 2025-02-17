import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/widgets/common_dropdown.dart';
import 'dart:io';

class ImageReimaginationDialog extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final Function(String) onFolderSelected;
  final Function(int, double, int) onReimaginationStart;
  final String title;
  final IconData icon;
  final bool showReimaginationSettings;

  const ImageReimaginationDialog({
    super.key,
    required this.onImagesSelected,
    required this.onFolderSelected,
    required this.onReimaginationStart,
    this.title = '图片重绘设置',
    this.icon = Icons.auto_fix_high_rounded,
    this.showReimaginationSettings = true,
  });

  @override
  State<ImageReimaginationDialog> createState() => _ImageReimaginationDialogState();
}

class _ImageReimaginationDialogState extends State<ImageReimaginationDialog> {
  List<String> selectedImages = [];
  String? selectedFolder;
  int reimagineCount = 1;
  double denoising = 0.75;
  int reverseType = 0;

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedImages = result.paths.whereType<String>().toList();
        selectedFolder = null;
      });
    }
  }

  Future<void> _pickFolder() async {
    String? result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      setState(() {
        selectedFolder = result;
        selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Dialog(
      backgroundColor: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  widget.icon,
                  color: settings.getSelectedBgColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: settings.getForegroundColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectedFolder == null ? _pickImages : null,
                            icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                            label: const Text('选择图片', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: settings.getSelectedBgColor(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: settings.getSelectedBgColor().withAlpha(128),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectedImages.isEmpty ? _pickFolder : null,
                            icon: const Icon(Icons.folder_rounded, color: Colors.white),
                            label: const Text('选择文件夹', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: settings.getSelectedBgColor(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: settings.getSelectedBgColor().withAlpha(128),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '已选择的图片',
                        style: TextStyle(
                          color: settings.getForegroundColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: settings.getForegroundColor().withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: selectedImages.length > 9 ? 9 : selectedImages.length,
                          itemBuilder: (context, index) {
                            if (index == 8 && selectedImages.length > 9) {
                              return Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: settings.getForegroundColor().withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${selectedImages.length - 8}',
                                    style: TextStyle(
                                      color: settings.getForegroundColor(),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(selectedImages[index]),
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (selectedFolder != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        '已选择的文件夹',
                        style: TextStyle(
                          color: settings.getForegroundColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.getForegroundColor().withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_rounded,
                              color: settings.getSelectedBgColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFolder!,
                                style: TextStyle(
                                  color: settings.getForegroundColor(),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.showReimaginationSettings) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            '每张图重绘数量',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: CommonDropdownWidget(
                              dropdownData: const ['1', '2', '3', '4'],
                              selectedValue: reimagineCount.toString(),
                              onChangeValue: (value) {
                                setState(() {
                                  reimagineCount = int.parse(value);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            '重绘幅度',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            denoising.toStringAsFixed(2),
                            style: TextStyle(
                              color: settings.getSelectedBgColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: settings.getSelectedBgColor(),
                          inactiveTrackColor: settings.getForegroundColor().withAlpha(25),
                          thumbColor: settings.getSelectedBgColor(),
                          overlayColor: settings.getSelectedBgColor().withAlpha(32),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: denoising,
                          min: 0,
                          max: 1,
                          divisions: 100,
                          onChanged: (value) {
                            setState(() {
                              denoising = value;
                            });
                          },
                        ),
                      ),
                    ],
                    if (!widget.showReimaginationSettings) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            '反推类型',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 180,
                            child: CommonDropdownWidget(
                              dropdownData: const ['ComfyUI', 'StableDiffusion'],
                              selectedValue: reverseType == 0 ? 'ComfyUI' : 'StableDiffusion',
                              onChangeValue: (value) {
                                setState(() {
                                  reverseType = value == 'ComfyUI' ? 0 : 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 按钮区域
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: settings.getSelectedBgColor(),
                    side: BorderSide(color: settings.getSelectedBgColor()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (selectedImages.isNotEmpty || selectedFolder != null)
                      ? () {
                          if (selectedImages.isNotEmpty) {
                            widget.onImagesSelected(selectedImages);
                          } else if (selectedFolder != null) {
                            widget.onFolderSelected(selectedFolder!);
                          }
                          widget.onReimaginationStart(
                            reimagineCount,
                            denoising,
                            reverseType,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.getSelectedBgColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('开始执行'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
