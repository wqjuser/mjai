import 'package:openai_dart/openai_dart.dart';
import 'package:tuitu/utils/common_methods.dart';
import '../config/config.dart';
import '../net/custom_http_client.dart';

class OpenAIClientSingleton {
  late OpenAIClient _client;
  late String _apiKey;
  late String _baseUrl;

  static final OpenAIClientSingleton _instance = OpenAIClientSingleton._internal();

  OpenAIClientSingleton._internal();

  static OpenAIClientSingleton get instance => _instance;

  Future<void> init() async {
    Map settings = await Config.loadSettings();
    _apiKey = settings['chat_api_key'] ?? settings['chatSettings_apiKey'] ?? '';
    _baseUrl = (settings['chat_api_url'] ?? settings['chatSettings_apiUrl'] ?? '') + '/v1';
    if (_apiKey.isEmpty) {
      commonPrint('AI聊天 API 密钥未设置，不初始化 OpenAI 客户端。');
      return;
    }
    if (_baseUrl == '/v1') {
      _baseUrl = 'https://api.openai.com/v1';
    }
    _initializeClient();
  }

  void _initializeClient() {
    _client = OpenAIClient(apiKey: _apiKey, baseUrl: _baseUrl, client: CustomHttpClient(timeout: const Duration(seconds: 100)));
  }

  OpenAIClient get client => _client;

  // New method to update API key
  void updateApiKey(String newApiKey) {
    _apiKey = newApiKey;
    _initializeClient();
  }

  // New method to update base URL
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl.contains('/v') ? newBaseUrl : '$newBaseUrl/v1';
    _initializeClient();
  }

  // New method to get current API key
  String get apiKey => _apiKey;

  // New method to get current base URL
  String get baseUrl => _baseUrl;
}
