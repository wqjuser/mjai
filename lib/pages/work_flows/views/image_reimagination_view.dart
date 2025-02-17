import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/change_settings.dart';
import '../../../widgets/image_reimagination_dialog.dart';
import '../view_models/image_reimagination_view_model.dart';

class ImageReimaginationView extends StatelessWidget {
  const ImageReimaginationView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final viewModel = context.watch<ImageReimaginationViewModel>();

    return Card(
      color: settings.getBackgroundColor(),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high_rounded,
                  color: settings.getForegroundColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '图片批量重绘工作流(CU-Flux)',
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!viewModel.isProcessing)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showImageReimaginationDialog(context, settings, viewModel),
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                  label: const Text('开始新任务', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.getSelectedBgColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: settings.getForegroundColor().withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: settings.getSelectedBgColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '处理进度',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: viewModel.progressPercentage,
                        backgroundColor: settings.getForegroundColor().withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          settings.getSelectedBgColor(),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${viewModel.currentImageIndex} / ${viewModel.totalImages}',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 14,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: viewModel.stopProcessing,
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                          label: const Text('停止', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageReimaginationDialog(
    BuildContext context,
    ChangeSettings settings,
    ImageReimaginationViewModel viewModel,
  ) async {
    // 检查ComfyUI状态
    if (await viewModel.checkComfyUIStatus()) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ImageReimaginationDialog(
            onImagesSelected: viewModel.setSelectedImages,
            onFolderSelected: viewModel.handleFolderSelected,
            onReimaginationStart: (count, denoising, _) {
              viewModel.setReimaginationParams(count, denoising);
            },
          ),
        );
      }
    }
  }
}
