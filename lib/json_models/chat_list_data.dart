class ChatListData {
  int id;
  String title;
  String createTime;
  String? modelName;
  int messagesCount;
  bool isSelected;

  ChatListData(
      {required this.id,
      required this.title,
      required this.createTime,
      this.modelName,
      this.messagesCount = 0,
      this.isSelected = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createTime': createTime,
      'modelName': modelName,
      'messagesCount': messagesCount,
      'isSelected': isSelected
    };
  }

  static fromJson(Map<String, dynamic> data) {
    return ChatListData(
      id: data['id'],
      title: data['title'],
      createTime: data['createTime'],
      modelName: data['modelName'],
      messagesCount: data['messagesCount'],
      isSelected: data['isSelected'],
    );
  }
}
