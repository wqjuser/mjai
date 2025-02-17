class ReverseEngineeringModel {
  bool isReverseProcessing = false;
  List<String> selectedReverseImages = [];
  String? selectedReverseFolder;
  int currentReverseIndex = 0;
  int totalReverseImages = 0;
  int useReverseType = 0; // 0: ComfyUI反推, 1: SD反推

  // 重置状态
  void reset() {
    isReverseProcessing = false;
    selectedReverseImages = [];
    selectedReverseFolder = null;
    currentReverseIndex = 0;
    totalReverseImages = 0;
  }

  // 更新处理进度
  void updateProgress(int current, int total) {
    currentReverseIndex = current;
    totalReverseImages = total;
  }

  // 设置选中的图片
  void setSelectedImages(List<String> images) {
    selectedReverseImages = images;
    totalReverseImages = images.length;
    currentReverseIndex = 0;
  }

  // 设置选中的文件夹
  void setSelectedFolder(String folder) {
    selectedReverseFolder = folder;
  }

  // 设置反推类型
  void setReverseType(int type) {
    useReverseType = type;
  }

  // 开始处理
  void startProcessing() {
    isReverseProcessing = true;
    currentReverseIndex = 0;
  }

  // 停止处理
  void stopProcessing() {
    isReverseProcessing = false;
  }

  // 获取处理进度百分比
  double get progressPercentage {
    return totalReverseImages > 0 ? currentReverseIndex / totalReverseImages : 0;
  }

  // 判断是否使用ComfyUI反推
  bool get isUsingComfyUI => useReverseType == 0;

  // 判断是否使用SD反推
  bool get isUsingSD => useReverseType == 1;
}