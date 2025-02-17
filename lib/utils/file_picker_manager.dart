import 'package:file_picker/file_picker.dart';
import 'package:tuitu/utils/common_methods.dart';

class FilePickerManager {
  // 私有构造函数
  FilePickerManager._();

  // 单例实例
  static final FilePickerManager _instance = FilePickerManager._();

  // 获取单例实例的工厂方法
  factory FilePickerManager() {
    return _instance;
  }

  // 标志变量，用于追踪文件选择对话框是否正在显示
  bool _isPickerDialogShowing = false;

  // 文件选择方法
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    String? customMessage, // 自定义提示消息
  }) async {
    // 如果对话框已经在显示，则显示提示信息
    if (_isPickerDialogShowing) {
      showHint(customMessage ?? '文件选择窗口已经打开，请先完成当前选择');
      return null;
    }

    try {
      // 设置对话框显示状态为 true
      _isPickerDialogShowing = true;

      // 调用文件选择器
      final result = await FilePicker.platform.pickFiles(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          type: type,
          allowedExtensions: allowedExtensions,
          allowMultiple: allowMultiple,
          onFileLoading: onFileLoading,
          lockParentWindow: true);

      return result;
    } finally {
      // 无论成功与否，都将状态设置回 false
      _isPickerDialogShowing = false;
    }
  }

  // 保存文件方法
  Future<String?> saveFile({
    required String fileName,
    String? dialogTitle,
    String? initialDirectory,
    List<String>? allowedExtensions,
    String? customMessage,
  }) async {
    // 如果对话框已经在显示，则显示提示信息
    if (_isPickerDialogShowing) {
      showHint(customMessage ?? '文件保存窗口已经打开，请先完成当前操作');
      return null;
    }

    try {
      _isPickerDialogShowing = true;

      // 调用文件选择器获取保存路径
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? '选择保存位置',
        fileName: fileName,
        initialDirectory: initialDirectory,
        type: FileType.any,
        allowedExtensions: allowedExtensions,
        lockParentWindow: true,
      );

      return outputFile;
    } finally {
      _isPickerDialogShowing = false;
    }
  }

  // 获取当前对话框状态
  bool get isDialogShowing => _isPickerDialogShowing;
}