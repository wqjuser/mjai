import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../config/config.dart';
import '../../../net/my_api.dart';
import '../../../utils/common_methods.dart';
import '../models/reverse_engineering_model.dart';
import '../../../work_flows/joy_i2t.dart';

class ReverseEngineeringViewModel extends ChangeNotifier {
  final ReverseEngineeringModel _model = ReverseEngineeringModel();
  final MyApi _api = MyApi();

  // Getters
  bool get isReverseProcessing => _model.isReverseProcessing;
  List<String> get selectedReverseImages => _model.selectedReverseImages;
  String? get selectedReverseFolder => _model.selectedReverseFolder;
  int get currentReverseIndex => _model.currentReverseIndex;
  int get totalReverseImages => _model.totalReverseImages;
  int get useReverseType => _model.useReverseType;
  double get progressPercentage => _model.progressPercentage;
  bool get isUsingComfyUI => _model.isUsingComfyUI;
  bool get isUsingSD => _model.isUsingSD;

  // 设置选中的图片并开始处理
  Future<void> setSelectedImages(List<String> images) async {
    _model.setSelectedImages(images);
    notifyListeners();
    await reverseImageTag(images);
  }

  // 设置选中的文件夹
  void setSelectedFolder(String folder) {
    _model.setSelectedFolder(folder);
    notifyListeners();
  }

  // 设置反推类型并重新检查服务状态
  Future<void> setReverseType(int type, List<String> selectedImages) async {
    if (_model.useReverseType == type) return; // 如果类型没有改变，不做任何处理

    _model.setReverseType(type);
    notifyListeners();

    // 如果已经选择了图片，立即使用新的反推类型开始处理
    // if (selectedImages.isNotEmpty) {
    //   await reverseImageTag(selectedImages);
    // }
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

    await setSelectedImages(imagePaths);
  }

  // 反推图片标签
  Future<void> reverseImageTag(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return;
    showHint('正在检查...', showType: 5);
    if (isUsingComfyUI) {
      // ComfyUI反推
      Response response = await _api.cuGetSystemStats();
      if (response.statusCode == 200) {
        startProcessing();
        dismissHint();
        await uploadImages(imagePaths);
      } else {
        showHint('ComfyUI未启动,请先启动ComfyUI');
        stopProcessing();
      }
    } else {
      // SD反推
      var settings = await Config.loadSettings();
      String sdUrl = settings['sdUrl'] ?? 'http://127.0.0.1:7860';
      Response response = await _api.testSDConnection(sdUrl);
      if (response.statusCode == 200) {
        dismissHint();
        await _reverseEngineering(imagePaths);
      } else {
        showHint('SD未启动,请先启动SD');
        stopProcessing();
      }
    }
  }

  // 上传图片到ComfyUI
  Future<void> uploadImages(List<String> paths) async {
    for (String path in paths) {
      try {
        final result = await _api.cuUploadImage(path);
        if (result.statusCode == 200) {
          String fileName = result.data['name'];

          // 设置反推参数
          final prompt = joyI2t;
          prompt['1']['inputs']['image'] = fileName;
          String baseFileName = fileName.split('.')[0];
          prompt['19']['inputs']['filename_prefix'] = '${baseFileName}_cu';

          String saveDirectory = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
          String reversePath = '$saveDirectory${Platform.pathSeparator}reverse_results';
          await commonCreateDirectory(reversePath);
          prompt['19']['inputs']['path'] = reversePath;

          // 执行反推
          await cuGetImages(prompt, isReImagine: false);

          // 更新进度
          _model.currentReverseIndex++;
          if (_model.currentReverseIndex == _model.totalReverseImages) {
            stopProcessing();
            showHint('所有图片反推完毕', showType: 2);
          }
          notifyListeners();
        }
      } catch (e) {
        commonPrint('上传图片失败: $e');
      }
    }
  }

  // SD反推
  Future<void> _reverseEngineering(List<String> paths) async {
    Map<String, dynamic> requestBody = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String sdUrl = settings['sdUrl'] ?? 'http://127.0.0.1:7860';
    try {
      for (String imagePath in paths) {
        requestBody['image'] = await imageToBase64(imagePath);
        requestBody['model'] = 'wd-v1-4-moat-tagger.v2';
        requestBody['threshold'] = 0.35;
        requestBody['escape_tag'] = false;
        requestBody['add_confident_as_weight'] = false;
        Response response = await _api.getTaggerTags(sdUrl, requestBody);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          String tags = '';
          Map<String, dynamic> tagsData = response.data['caption']['tag'];
          for (String key in tagsData.keys) {
            tags += '$key, ';
          }
          String saveDirectory = imagePath.substring(0, imagePath.lastIndexOf(Platform.pathSeparator));
          String reversePath = '$saveDirectory${Platform.pathSeparator}reverse_results';
          await commonCreateDirectory(reversePath);

          String fileName = path.basenameWithoutExtension(imagePath);
          String txtFilePath = '$reversePath${Platform.pathSeparator}${fileName}_sd.txt';

          File txtFile = File(txtFilePath);
          await txtFile.writeAsString(tags.trimRight().replaceAll(RegExp(r',\s*$'), ''));

          // 更新进度
          _model.currentReverseIndex++;
          if (_model.currentReverseIndex == _model.totalReverseImages) {
            stopProcessing();
            showHint('所有图片反推完毕', showType: 2);
          }
          notifyListeners();
        }
      }
    } finally {
      try {
        Response response = await _api.unloadTaggerModels(sdUrl, null);
        if (response.statusCode == 200) {
          commonPrint('反推模型卸载成功: ${response.data}');
        } else {
          commonPrint('反推模型卸载失败: ${response.statusMessage}');
        }
      } catch (e) {
        commonPrint('反推模型卸载出错: $e');
      }
    }
  }

  // 重置状态
  void reset() {
    _model.reset();
    notifyListeners();
  }
}
