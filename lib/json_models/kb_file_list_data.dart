class KBFileListData {
  String id;
  String title;
  String createTime;
  bool isSelected;
  bool isChangingName;
  String status;
  String fileSize;

  KBFileListData(
      {required this.id,
      required this.title,
      required this.createTime,
      this.isSelected = true,
      this.status = '0',
      this.fileSize = '',
      this.isChangingName = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': title,
      'create_time': createTime,
      'is_selected': isSelected,
      'status': status,
      'fileSize': fileSize,
      'is_changing_name': isChangingName
    };
  }
}
