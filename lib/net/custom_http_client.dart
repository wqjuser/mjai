import 'dart:async';  // 包含 TimeoutException
import 'package:http/http.dart' as http;

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  // 构造函数可以接收其他自定义参数，如超时时间等
  final Duration timeout;

  CustomHttpClient({this.timeout = const Duration(seconds: 30)});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 在这里可以添加自定义的请求处理逻辑
    // commonPrint('请求的URL: ${request.url}');

    try {
      // 使用超时时间并捕获超时异常
      return await _inner.send(request).timeout(timeout);
    } on TimeoutException catch (_) {
      // 抛出超时异常
      throw TimeoutException('请求超时，超过了 ${timeout.inSeconds} 秒');
    }
  }

  @override
  void close() {
    _inner.close(); // 关闭内部的 http.Client
  }
}
