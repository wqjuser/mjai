import 'dart:async';
import 'package:dio/dio.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/json_models/music_response_entity.dart';
import 'package:tuitu/json_models/video_list_data.dart';
import 'package:uuid/uuid.dart';
import '../config/config.dart';
import '../json_models/chat_web_response_entity.dart';
import 'api_base.dart';
import 'dart:io';

class MyApi extends ApiBase {
  MyApi([Dio? dio]) : super(dio ?? Dio());

  Future<Response> testSDConnection(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}app_id';
    } else {
      url = '$url/app_id';
    }
    return get(url);
  }

  Future<Response> getSDLoras(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/loras';
    } else {
      url = '$url/sdapi/v1/loras';
    }
    return get(url);
  }

  Future<Response> getSDModels(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/sd-models';
    } else {
      url = '$url/sdapi/v1/sd-models';
    }
    return get(url);
  }

  Future<Response> getSDVaes(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/sd-vae';
    } else {
      url = '$url/sdapi/v1/sd-vae';
    }
    return get(url);
  }

  Future<Response> getSDSamplers(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/samplers';
    } else {
      url = '$url/sdapi/v1/samplers';
    }
    return get(url);
  }

  Future<Response> getSDUpscalers(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/upscalers';
    } else {
      url = '$url/sdapi/v1/upscalers';
    }
    return get(url);
  }

  Future<Response> getSDlLatentUpscaleModes(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/latent-upscale-modes';
    } else {
      url = '$url/sdapi/v1/latent-upscale-modes';
    }
    return get(url);
  }

  Future<Response> sdText2Image(String sdUrl, Map<String, dynamic> requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/txt2img';
    } else {
      url = '$url/sdapi/v1/txt2img';
    }
    return post(url, requestBody);
  }

  Future<Response> sdImage2Image(String sdUrl, Map<String, dynamic> requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/img2img';
    } else {
      url = '$url/sdapi/v1/img2img';
    }
    return post(url, requestBody);
  }

  Future<Response> sdUpScaleImage(String sdUrl, Map<String, dynamic> requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/extra-single-image';
    } else {
      url = '$url/sdapi/v1/extra-single-image';
    }
    return post(url, requestBody);
  }

  Future<Response> setSDOptions(String sdUrl, Map<String, dynamic> requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/options';
    } else {
      url = '$url/sdapi/v1/options';
    }
    return post(url, requestBody);
  }

  Future<Response> getSDOptions(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}sdapi/v1/options';
    } else {
      url = '$url/sdapi/v1/options';
    }
    return get(url);
  }

  Future<Response> getSDControlNetSettings(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}controlnet/settings';
    } else {
      url = '$url/controlnet/settings';
    }
    return get(url);
  }

  Future<Response> getSDControlNetModels(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}controlnet/model_list?update=true';
    } else {
      url = '$url/controlnet/model_list?update=true';
    }
    return get(url);
  }

  Future<Response> getSDControlNetModules(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}controlnet/module_list?alias_names=true';
    } else {
      url = '$url/controlnet/module_list?alias_names=true';
    }
    return get(url);
  }

  Future<Response> getSDControlNetControlTypes(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}controlnet/control_types';
    } else {
      url = '$url/controlnet/control_types';
    }
    return get(url);
  }

  Future<Response> getTaggerInterrogators(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}tagger/v1/interrogators';
    } else {
      url = '$url/tagger/v1/interrogators';
    }
    return get(url);
  }

  Future<Response> getTaggerTags(String sdUrl, Map<String, dynamic> requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}tagger/v1/interrogate';
    } else {
      url = '$url/tagger/v1/interrogate';
    }
    return post(url, requestBody);
  }

  Future<Response> unloadTaggerModels(String sdUrl, Map<String, dynamic>? requestBody) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}tagger/v1/unload-interrogators';
    } else {
      url = '$url/tagger/v1/unload-interrogators';
    }
    return post(url, null);
  }

  Future<Response> testChatGPT(String apiKey) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String? chatGPTApiUrl = settings['chat_api_url'];
    var url = "https://youraihelper.xyz/v1/chat/completions";
    if (chatGPTApiUrl != null && chatGPTApiUrl != '') {
      if (chatGPTApiUrl.endsWith('/')) {
        url = '$chatGPTApiUrl/v1/chat/completions';
      } else {
        url = '${chatGPTApiUrl}v1/chat/completions';
      }
    }
    Options options = Options(headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });
    Map<String, dynamic> requestBody = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "你好"}
      ]
    };
    return post(url, requestBody, options: options);
  }

  Future<Response> getGroupTags(String sdUrl) async {
    var url = sdUrl;
    if (url.endsWith('/')) {
      url = '${url}physton_prompt/get_group_tags?lang=zh_CN';
    } else {
      url = '$url/physton_prompt/get_group_tags?lang=zh_CN';
    }
    return get(url);
  }

  Future<Response> getDrawCanUseTimes(String applicationId, String zsyToken) async {
    var url = 'https://data.zhishuyun.com/api/v1/applications/$applicationId';
    Map<String, dynamic> headers = {'accept': 'application/json', 'authorization': 'Bearer $zsyToken'};
    return get(url, otherOptions: Options(headers: headers));
  }

  Future<Response> mjDraw(int type, String token, Map<String, dynamic> payload) async {
    var url = '';
    switch (type) {
      case 0:
        url = 'https://api.zhishuyun.com/midjourney/imagine/relax?token=$token';
        break;
      case 1:
        url = 'https://api.zhishuyun.com/midjourney/imagine?token=$token';
        break;
      case 2:
        url = 'https://api.zhishuyun.com/midjourney/imagine/turbo?token=$token';
        break;
      default:
        break;
    }
    Map<String, dynamic> headers = {'accept': 'application/x-ndjson', 'content-type': 'application/json'};
    return post(url, payload,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ));
  }

  Future<Response> testMJConnect() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    var url = '$mjBaseUrl/mj/home';
    return get(url, otherOptions: Options(headers: headers));
  }

  Future<Response> mjBlend(String token, Map<String, dynamic> payload) async {
    Map<String, dynamic> headers = {'accept': 'application/x-ndjson', 'content-type': 'application/json'};
    String url = 'https://api.zhishuyun.com/midjourney/blend?token=$token';
    return post(url, payload,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ));
  }

  Future<Response> mjDescribe(String token, Map<String, dynamic> payload) async {
    var url = 'https://api.zhishuyun.com/midjourney/describe?token=$token';
    Map<String, dynamic> headers = {'accept': 'application/json', 'content-type': 'application/json'};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjDrawCreate(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/imagine';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjDrawChange(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/action';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjDescribe(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/describe';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjBlend(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/blend';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjDrawQuery(String taskId, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/task/$taskId/fetch';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return get(url, otherOptions: Options(headers: headers));
  }

  Future<Response> selfMjGetImageSeed(String taskId, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/task/$taskId/image-seed';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return get(url, otherOptions: Options(headers: headers));
  }

  Future<Response> selfMjShorten(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/shorten';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> selfMjModal(Map<String, dynamic> payload, {int drawSpeedType = 1}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    switch (drawSpeedType) {
      case 0: //慢速
        mjBaseUrl += '/mj-relax';
        break;
      case 1: //快速
        mjBaseUrl += '';
        break;
      case 2: //极速
        mjBaseUrl += '/mj-turbo';
        break;
      default:
        mjBaseUrl += '/mj-relax';
        break;
    }
    var url = '$mjBaseUrl/mj/submit/modal';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> uploadImage(Object? payload) async {
    String url = 'https://telegraph-image-6mz.pages.dev/upload';
    return post(url, payload);
  }

  Future<Response> uploadFile(Object? payload, {CancelToken? cancelToken, Options? options}) async {
    String url = 'https://file.zxai.fun/upload';
    return post(url, payload, cancelToken: cancelToken, options: options);
  }

  Future<Response> uploadFileToMoonshot(Object? payload, String inputUrl, {Options? options, CancelToken? cancelToken}) async {
    String url = inputUrl;
    return post(url, payload, options: options, cancelToken: cancelToken);
  }

  Future<Response> getFileContentFromMoonshot(String inputUrl, {Options? options, CancelToken? cancelToken}) async {
    String url = inputUrl;
    return get(url, otherOptions: options, cancelToken: cancelToken);
  }

  Future<Response<ChatWebResponseEntity>> testWebChatGPT(String proxyPath) async {
    var url = proxyPath;
    Map<String, dynamic> requestBody = {
      "model": "gpt-3.5-turbo-0613",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "你好"}
      ],
    };
    try {
      final response = await Dio().post(url, data: requestBody);
      if (response.statusCode == 200) {
        final chatWebResponse = ChatWebResponseEntity.fromJson(response.data);
        return Response<ChatWebResponseEntity>(
          data: chatWebResponse,
          headers: response.headers,
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
        );
      } else {
        return Response<ChatWebResponseEntity>(
          data: ChatWebResponseEntity(),
          headers: response.headers,
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch chatWebResponse');
    }
  }

  Future<Response> tyqwAI(Map<String, dynamic> payload, {bool isStream = false}) async {
    String url = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
    Map<String, dynamic> settings = await Config.loadSettings();
    String tyqwApiKey = settings['tyqw_api_key'] ?? '';
    Map<String, dynamic> headers = {'Authorization': 'Bearer $tyqwApiKey', 'Content-Type': 'application/json'};
    Options options = Options();
    if (isStream) {
      headers['X-DashScope-SSE'] = 'enable';
      options.responseType = ResponseType.stream;
    }
    options.headers = headers;
    return post(url, payload, options: options);
  }

  Future<Response> zpai(Map<String, dynamic> payload, String token, {String model = 'ChatGLM-Lite', bool isStream = false}) async {
    String url = 'https://open.bigmodel.cn/api/api/v3/model-api/$model/${isStream ? "sse-invoke" : "invoke"}';
    Map<String, dynamic> headers = {'Authorization': token};
    Options options = Options();
    if (isStream) {
      options.responseType = ResponseType.stream;
    }
    options.headers = headers;
    return post(url, payload, options: options);
  }

  Future<Response> addMJAccount(Map<String, dynamic> accountInfo) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    var url = '$mjBaseUrl/mj/account/create';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, accountInfo, options: Options(headers: headers));
  }

  Future<Response> updateAndReconnectMJAccount(Map<String, dynamic> payload, String id) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    var url = '$mjBaseUrl/mj/account/$id/update-reconnect';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return put(url, payload, options: Options(headers: headers));
  }

  Future<Response> swapFace(Map<String, dynamic> payload) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    var url = '$mjBaseUrl/mj/insight-face/swap';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return post(url, payload, options: Options(headers: headers));
  }

  Future<Response> deleteMJAccount(String accountId) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String mjApiUrl = settings['mj_api_url'] ?? '';
    bool urlEmpty = mjApiUrl == '';
    String apiSecret = settings['mj_api_secret'] ?? '';
    bool secretEmpty = apiSecret == '';
    String mjBaseUrl = urlEmpty ? GlobalParams.mjApiUrl : mjApiUrl;
    String mjApiSecret = secretEmpty ? GlobalParams.mjApiSecret : apiSecret;
    var url = '$mjBaseUrl/mj/account/$accountId/delete';
    Map<String, dynamic> headers = {'mj-api-secret': mjApiSecret};
    return delete(url, null, options: Options(headers: headers));
  }

  Future<Response> cuQueuePrompt(Map<String, dynamic> requestBody) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String cuUrl = settings['cu_url'] ?? 'http://127.0.0.1:8188';
    String clientId = settings['client_id'] ?? const Uuid().v4();
    if (cuUrl.endsWith('/')) {
      cuUrl = '${cuUrl}prompt';
    } else {
      cuUrl = '$cuUrl/prompt';
    }
    final Map<String, dynamic> requestData = {'prompt': requestBody, 'client_id': clientId};
    return post(cuUrl, requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ));
  }

  Future<Response> cuUploadImage(String filePath) async {
    filePath = filePath.replaceAll('\\', '/');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    Map<String, dynamic> settings = await Config.loadSettings();
    String cuUrl = settings['cu_url'] ?? 'http://127.0.0.1:8188';
    final uploadUrl = cuUrl.endsWith('/') ? '${cuUrl}upload/image' : '$cuUrl/upload/image';
    final options = Options(
      headers: {
        'Accept': '*/*',
        'Content-Type': 'multipart/form-data',
      },
      followRedirects: false,
      validateStatus: (status) => true,
    );

    return post(uploadUrl, formData, options: options);
  }

  Future<Response> cuGetHistory(String promptId) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String cuUrl = settings['cu_url'] ?? 'http://127.0.0.1:8188';
    if (cuUrl.endsWith('/')) {
      cuUrl = '${cuUrl}history/$promptId';
    } else {
      cuUrl = '$cuUrl/history/$promptId';
    }
    return get(cuUrl);
  }

  Future<Response> cuGetImage(String filename, String subfolder, String folderType) async {
    final Map<String, String> data = {
      'filename': filename,
      'subfolder': subfolder,
      'type': folderType,
    };
    Map<String, dynamic> settings = await Config.loadSettings();
    String cuUrl = settings['cu_url'] ?? 'http://127.0.0.1:8188';
    if (cuUrl.endsWith('/')) {
      cuUrl = '${cuUrl}view';
    } else {
      cuUrl = '$cuUrl/view';
    }
    final String url = "$cuUrl${Uri(queryParameters: data)}";
    return get(url, otherOptions: Options(responseType: ResponseType.bytes));
  }

  Future<Response> cuGetSystemStats() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String cuUrl = settings['cu_url'] ?? 'http://127.0.0.1:8188';
    if (cuUrl.endsWith('/')) {
      cuUrl = '${cuUrl}system_stats';
    } else {
      cuUrl = '$cuUrl/system_stats';
    }
    return get(cuUrl);
  }

  Future<Response> fsGetSystemStats() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    if (fsUrl.endsWith('/')) {
      fsUrl = fsUrl;
    } else {
      fsUrl = '$fsUrl/';
    }
    return get(fsUrl);
  }

  Future<Response> fsGetModels() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    if (fsUrl.endsWith('/')) {
      fsUrl = '${fsUrl}v1/engines/all-models';
    } else {
      fsUrl = '$fsUrl/v1/engines/all-models';
    }
    return get(fsUrl);
  }

  Future<Response> fsGetStyles() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    if (fsUrl.endsWith('/')) {
      fsUrl = '${fsUrl}v1/engines/styles';
    } else {
      fsUrl = '$fsUrl/v1/engines/styles';
    }
    return get(fsUrl);
  }

  Future<Response> fsCreateImages(Map<String, dynamic> requestBody) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    if (fsUrl.endsWith('/')) {
      fsUrl = '${fsUrl}v1/generation/text-to-image';
    } else {
      fsUrl = '$fsUrl/v1/generation/text-to-image';
    }
    return post(fsUrl, requestBody);
  }

  Future<Response> getUrlContent(String url) async {
    return get('https://r.jina.ai/$url');
  }

  Future<Response> getSearchResult(String question) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String chatSettingsUseNetUrl = settings['chatSettings_useNetUrl'] ?? '';
    int searchNum = (settings['chatSettings_netSearch'] ?? 10).toInt();
    String searchUrl = '$chatSettingsUseNetUrl?keyword=$question&max_results=$searchNum';
    return get(searchUrl);
  }

  Future<Response> createPay(String url, Map<String, dynamic> queryParams) async {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    String fullUrl = '$url/mapi.php';
    return post(fullUrl, null, queryParameters: queryParams);
  }

  Future<Response> queryPay(String url, Map<String, dynamic> queryParams) async {
    String fullUrl = '$url/api.php?act=order&pid=${queryParams['pid']}&key=${queryParams['key']}&trade_no=${queryParams['trade_no']}';
    return get(fullUrl);
  }

  Future<Response> getCurrentIP() async {
    return get('https://api.ipify.org?format=json');
  }

  Future<Response> createKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/create_kb';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> deleteKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/delete_kb';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> uploadFileKB(dynamic queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/upload_file';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'multipart/form-data';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> uploadUrlKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/upload_url';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> deleteFileKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/delete_file';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> listKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/kb_list';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    return get(url, headerOptions: headers);
  }

  Future<Response> fileListKB(Map<String, dynamic> queryParams) async {
    String kbId = queryParams['kbId'];
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/file_list?kbId=$kbId';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    return get(url, headerOptions: headers);
  }

  Future<Response> changeKBTitle(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/kb_config';
    Map<String, dynamic> headers = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    headers['Authorization'] = appKey;
    headers['Content-Type'] = 'application/json';
    Options options = Options(headers: headers);
    return post(url, queryParams, options: options);
  }

  Future<Response> chatStreamKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/chat_stream';
    Map<String, dynamic> settings = await Config.loadSettings();
    String appKey = settings['kb_app_id'] ?? '';
    var options = Options(
      responseType: ResponseType.stream,
      headers: {'Content-Type': 'application/json', 'Authorization': appKey},
    );
    return post(url, queryParams, options: options);
  }

  Future<Response> chatKB(Map<String, dynamic> queryParams) async {
    String url = '${GlobalParams.qaBaseUrl}/q_anything/api/chat';
    return post(url, queryParams);
  }

  Future<Response> getVideo(String ids) async {
    final apiUrl = '${GlobalParams.lumaLabsInternalUrl}$ids';
    return get(apiUrl, headerOptions: GlobalParams.lumaCommonHeaders);
  }

  Future<Response> getLumaUploadImageLink() async {
    final url = '${GlobalParams.lumaLabsInternalUrl}file_upload';
    Map<String, dynamic> data = {'file_type': 'image', 'filename': 'file.jpg'};
    Map<String, dynamic> settings = await Config.loadSettings();
    String cookie = settings['luma_cookie'] ?? '';
    Map<String, dynamic> headers = GlobalParams.lumaCommonHeaders;
    headers['Cookie'] = cookie;
    Options options = Options(headers: headers);
    return post(url, data, options: options);
  }

  Future<Response> lumaUploadImage(String filePath, String uploadUrl) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String cookie = settings['luma_cookie'] ?? '';
    final headers = GlobalParams.lumaUploadHeaders;
    headers['Cookie'] = cookie;
    Options options = Options(headers: headers);
    File file = File(filePath);
    FormData formData = FormData.fromMap({'file': await MultipartFile.fromFile(filePath, filename: file.path.split('/').last)});
    return post(uploadUrl, formData, options: options);
  }

  Future<Response> lumaGenerateVideo(Map<String, dynamic> payload, {bool isSelf = true}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String url = '';
    if (isSelf) {
      String cookie = settings['luma_cookie'] ?? '';
      url = GlobalParams.lumaLabsInternalUrl;
      final headers = GlobalParams.lumaCommonHeaders;
      headers['Cookie'] = cookie;
      Options options = Options(headers: headers);
      return post(url, payload, options: options);
    } else {
      String lumaApiToken = settings['luma_api_token'] ?? '';
      String lumaApiUrl = settings['luma_api_url'] ?? '';
      Map<String, dynamic> headers = {'Authorization': 'Bearer $lumaApiToken'};
      Options options = Options(headers: headers);
      url = '${lumaApiUrl}generations';
      return post(url, payload, options: options);
    }
  }

  Future<Response> lumaGetVideo(VideoListData videoData) async {
    String url = '';
    if (videoData.isSelf) {
      url = GlobalParams.lumaLabsInternalUrl + videoData.videoId;
      return get(url);
    } else {
      Map<String, dynamic> settings = await Config.loadSettings();
      String lumaApiToken = settings['luma_api_token'] ?? '';
      String lumaApiUrl = settings['luma_api_url'] ?? '';
      Map<String, dynamic> headers = {'Authorization': 'Bearer $lumaApiToken'};
      url = '${lumaApiUrl}generations/${videoData.videoId}';
      return get(url, headerOptions: headers);
    }
  }

  Future<Response> lumaExtendVideo(VideoListData videoData, dynamic data) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    if (videoData.isSelf) {
      String cookie = settings['luma_cookie'] ?? '';
      String videoId = videoData.videoId;
      final headers = GlobalParams.lumaCommonHeaders;
      headers['Cookie'] = cookie;
      Options options = Options(headers: headers);
      return post('${GlobalParams.lumaLabsInternalUrl}$videoId/extend', data, options: options);
    } else {
      String lumaApiToken = settings['luma_api_token'] ?? '';
      String lumaApiUrl = settings['luma_api_url'] ?? '';
      String videoId = videoData.videoId;
      Map<String, dynamic> headers = {'Authorization': 'Bearer $lumaApiToken'};
      Options options = Options(headers: headers);
      return post('$lumaApiUrl$videoId/extend', data, options: options);
    }
  }

  Future<MusicResponseEntity?> sunoGenerateMusic(Map<String, dynamic> payload) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String sunoApikey = settings['suno_api_key'] ?? '';
    String sunoApiUrl = settings['suno_api_url'] ?? '';
    Map<String, dynamic> headers = {'Authorization': 'Bearer $sunoApikey'};
    Options options = Options(headers: headers);
    String url = sunoApiUrl.endsWith('/') ? '${sunoApiUrl}v2/generate' : '$sunoApiUrl/v2/generate';
    return postAndParse(
      url,
      payload,
      (data) => MusicResponseEntity.fromJson(data),
      options: options,
    );
  }

  Future<Response> sunoGenerateLyrics(Map<String, dynamic> payload) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String url = '';
    String sunoApikey = settings['suno_api_key'] ?? '';
    String sunoApiUrl = settings['suno_api_url'] ?? '';
    Map<String, dynamic> headers = {'Authorization': 'Bearer $sunoApikey'};
    Options options = Options(headers: headers);
    url = sunoApiUrl.endsWith('/') ? '${sunoApiUrl}v1/v3.0/lyrics' : '$sunoApiUrl/v1/v3.0/lyrics';
    return post(url, payload, options: options);
  }

  Future<Response> sunoGetLyrics(String lyricsId) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String url = '';
    String sunoApikey = settings['suno_api_key'] ?? '';
    String sunoApiUrl = settings['suno_api_url'] ?? '';
    Map<String, dynamic> headers = {'Authorization': 'Bearer $sunoApikey'};
    url = sunoApiUrl.endsWith('/') ? '${sunoApiUrl}v1/v3.0/lyrics/$lyricsId' : '$sunoApiUrl/v1/v3.0/lyrics/$lyricsId';
    return get(url, headerOptions: headers);
  }

  Future<Response> sunoGetMusic(String clipIds) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String url = '';
    String sunoApikey = settings['suno_api_key'] ?? '';
    String sunoApiUrl = settings['suno_api_url'] ?? '';
    Map<String, dynamic> headers = {'Authorization': 'Bearer $sunoApikey'};
    url = sunoApiUrl.endsWith('/') ? '${sunoApiUrl}v2/feed?ids=$clipIds' : '$sunoApiUrl/v2/feed?ids=$clipIds';
    return get(url, headerOptions: headers);
  }

  Future<Response> downloadSth(String url, String savePath, {ProgressCallback? onReceiveProgress}) {
    return download(url, savePath, onReceiveProgress: onReceiveProgress);
  }

  Future<Response> getVersionInfo(String url) async {
    return get(url);
  }

  Future<Response> getMessageTokens(Map<String, dynamic> payload) async {
    String url = 'https://oss.zxai.fun/tiktokens';
    return post(url, payload);
  }

  Future<Response> myTranslate(Map<String, dynamic> payload, Options? options) async {
    String url = 'https://deeplx.zxai.fun/translate';
    return post(url, payload, options: options);
  }

  Future<Response> zhipuGenerateImage(Map<String, dynamic> payload, Options? options) async {
    String url = '${GlobalParams.zhipuBaseUrl}images/generations';
    return post(url, payload, options: options);
  }

  Future<Response> zhipuGenerateVideo(Map<String, dynamic> payload, Options? options) async {
    String url = '${GlobalParams.zhipuBaseUrl}videos/generations';
    return post(url, payload, options: options);
  }

  Future<Response> zhipuGetVideo(String videoId, Options? options) async {
    String url = '${GlobalParams.zhipuBaseUrl}async-result/$videoId';
    return get(url, otherOptions: options);
  }

  Future<Response> getFSStyles() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    if (fsUrl.endsWith('/')) {
      fsUrl = '${fsUrl}v1/engines/styles';
    } else {
      fsUrl = '$fsUrl/v1/engines/styles';
    }
    return get(fsUrl);
  }

  Future<Response> getFSModels(bool isBase) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String fsUrl = settings['fs_url'] ?? 'http://127.0.0.1:8888';
    String endpoint = isBase ? 'base-models' : 'refiner-models';
    if (fsUrl.endsWith('/')) {
      fsUrl = '${fsUrl}v1/engines/$endpoint';
    } else {
      fsUrl = '$fsUrl/v1/engines/$endpoint';
    }
    return get(fsUrl);
  }
}
