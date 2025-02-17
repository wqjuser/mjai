import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../net/my_api.dart';
import '../../../utils/common_methods.dart';
import '../../../work_flows/flux_i2i.dart';
import '../models/image_reimagination_model.dart';

class ImageReimaginationViewModel extends ChangeNotifier {
  final ImageReimaginationModel _model = ImageReimaginationModel();
  final MyApi _api = MyApi();

  // Getters
  List<String> get selectedImages => _model.selectedImages;
  String? get selectedFolder => _model.selectedFolder;
  int get reimagineCount => _model.reimagineCount;
  double get reimagineDenoising => _model.reimagineDenoising;
  bool get isProcessing => _model.isProcessing;
  int get currentImageIndex => _model.currentImageIndex;
  int get totalImages => _model.totalImages;
  double get progressPercentage => _model.progressPercentage;

  // 设置选中的图片并开始处理
  Future<void> setSelectedImages(List<String> images) async {
    _model.setSelectedImages(images);
    startProcessing();
    await uploadImages(images);
    notifyListeners();
  }

  // 设置选中的文件夹
  void setSelectedFolder(String folder) {
    _model.setSelectedFolder(folder);
    notifyListeners();
  }

  // 设置重绘参数
  void setReimaginationParams(int count, double denoising) {
    _model.setReimaginationParams(count, denoising);
    notifyListeners();
  }

  // 开始处理
  void startProcessing() {
    _model.startProcessing();
    notifyListeners();
  }

  // 停止处理
  void stopProcessing() {
    _model.stopProcessing();
    notifyListeners();
  }

  // 更新进度
  void updateProgress(int current, int total) {
    _model.updateProgress(current, total);
    notifyListeners();
  }

  // 处理文件夹选择
  Future<void> handleFolderSelected(String folder) async {
    final dir = Directory(folder);
    final imagePaths = await dir
        .list()
        .where((entity) =>
            entity is File &&
            (entity.path.toLowerCase().endsWith('.jpg') || entity.path.toLowerCase().endsWith('.jpeg') || entity.path.toLowerCase().endsWith('.png')))
        .toList()
        .then((list) => list.whereType<File>().map((e) => e.path).toList());

    setSelectedImages(imagePaths);
  }

  // 上传图片
  Future<void> uploadImages(List<String> paths) async {
    for (String path in paths) {
      try {
        final result = await _api.cuUploadImage(path);
        if (result.statusCode == 200) {
          String fileName = result.data['name'];

          // 设置重绘参数
          final prompt = fluxI2I;
          prompt['44']['inputs']['image'] = fileName;
          prompt['59']['inputs']['batch_size'] = reimagineCount;
          prompt['17']['inputs']['denoise'] = reimagineDenoising;
          prompt['25']['inputs']['noise_seed'] = generate15DigitNumber();
          prompt['57']['inputs']['seed'] = generate15DigitNumber();
          prompt['64']['inputs']['filename_prefix'] = 'reimagine_';

          // 执行重绘
          await cuGetImages(prompt);

          // 更新进度
          _model.currentImageIndex++;
          if (_model.currentImageIndex == _model.totalImages) {
            stopProcessing();
            showHint('所有图片重绘完毕', showType: 2);
          }
          notifyListeners();
        }
      } catch (e) {
        commonPrint('上传图片失败: $e');
      }
    }
  }

  // 检查ComfyUI状态
  Future<bool> checkComfyUIStatus() async {
    showHint('正在检查ComfyUI状态...', showType: 5);
    try {
      Response response = await _api.cuGetSystemStats();
      if (response.statusCode != 200) {
        showHint('ComfyUI未启动,请先启动ComfyUI', showType: 3);
      }
      return response.statusCode == 200;
    } catch (e) {
      commonPrint('检查ComfyUI状态失败: $e');
      return false;
    }
  }

  // 重置状态
  void reset() {
    _model.reset();
    notifyListeners();
  }
}
