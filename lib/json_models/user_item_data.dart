class UserItemData {
  String userId;
  String userDeviceId;
  String userName;
  String userEmail;
  String userPassword;
  bool userStatus;

  UserItemData({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    required this.userStatus,
    this.userDeviceId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userDeviceId': userDeviceId,
      'userName': userName,
      'userEmail': userEmail,
      'userPassword': userPassword,
      'userStatus': userStatus
    };
  }
}
