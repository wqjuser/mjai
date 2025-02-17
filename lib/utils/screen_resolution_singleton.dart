import 'common_methods.dart';

class ScreenResolutionSingleton {
  // 私有构造函数
  ScreenResolutionSingleton._privateConstructor();

  // 单例对象
  static final ScreenResolutionSingleton _instance = ScreenResolutionSingleton._privateConstructor();

  // 静态方法获取单例实例
  static ScreenResolutionSingleton get instance => _instance;

  // 用于保存已解析的屏幕分辨率
  String? _resolvedScreenResolution;

  // 异步初始化方法
  Future<void> init() async {
    // 假设screenResolutionChecker是一个异步方法，返回屏幕分辨率的字符串
    _resolvedScreenResolution = await screenResolutionChecker();
  }

  // 同步访问屏幕分辨率
  String? get screenResolution => _resolvedScreenResolution;
}
