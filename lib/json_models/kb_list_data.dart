class KBListData {
  String id;
  String title;
  String createTime;
  String modifyTime;
  bool isSelected;
  bool isChangingName;
  int filesNum;

  KBListData(
      {required this.id,
      required this.title,
      required this.createTime,
      required this.modifyTime,
      this.isSelected = true,
      this.isChangingName = false,
      this.filesNum = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': title,
      'create_time': createTime,
      'modify_time': modifyTime,
      'is_selected': isSelected,
      'files_num': filesNum,
      'is_changing_name': isChangingName
    };
  }
}
