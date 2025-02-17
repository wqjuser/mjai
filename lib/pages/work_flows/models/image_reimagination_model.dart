class ImageReimaginationModel {
  List<String> selectedImages = [];
  String? selectedFolder;
  int reimagineCount = 1;
  double reimagineDenoising = 0.75;
  bool isProcessing = false;
  int currentImageIndex = 0;
  int totalImages = 0;

  // 重置状态
  void reset() {
    selectedImages = [];
    selectedFolder = null;
    isProcessing = false;
    currentImageIndex = 0;
    totalImages = 0;
  }

  // 更新处理进度
  void updateProgress(int current, int total) {
    currentImageIndex = current;
    totalImages = total;
  }

  // 设置选中的图片
  void setSelectedImages(List<String> images) {
    selectedImages = images;
    totalImages = images.length;
    currentImageIndex = 0;
  }

  // 设置选中的文件夹
  void setSelectedFolder(String folder) {
    selectedFolder = folder;
  }

  // 设置重绘参数
  void setReimaginationParams(int count, double denoising) {
    reimagineCount = count;
    reimagineDenoising = denoising;
  }

  // 开始处理
  void startProcessing() {
    isProcessing = true;
    currentImageIndex = 0;
  }

  // 停止处理
  void stopProcessing() {
    isProcessing = false;
  }

  // 获取处理进度百分比
  double get progressPercentage {
    return totalImages > 0 ? currentImageIndex / totalImages : 0;
  }
}