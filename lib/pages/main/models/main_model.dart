class MainModel {
  String title = 'AI助手';
  List<String> titles = ['AI助手', 'AI绘画', 'AI视频', 'AI音乐', '小说推文助手', '艺术图片生成', '工作流', '知识库', '画廊', '用户管理', '套餐设置', '购买套餐', '设置'];
  int selectedIndex = 0;
  bool isRegistered = false;
  bool isLogin = false;
  String userName = '';
  String email = '';
  String password = '';
  bool showBroadcast = false;
  String broadcastMessage = '';
  bool showScrollIndicator = true;
  bool isAppIntoFullScreen = false;
  Map<String, dynamic> userQuotas = {};
  List imagesList = [];
  String topImageUrl = '';
  double sponsorAmount = 10.0;
  double windowHeight = 750;
  bool rememberChoice = true;
  List<Map<String, dynamic>> menus = [];
  bool isSSODialogOpen = false;
}
