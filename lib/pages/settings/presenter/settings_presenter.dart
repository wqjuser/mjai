import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/file_picker_manager.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:path/path.dart' as path;

class SettingsPresenter {
  final SettingsState state;
  final MyApi myApi = MyApi();
  SettingsPresenter({required this.state});

  // ====== AI引擎相关 ======
  Future<void> testOpenAI(
    String apiUrl,
    String model,
    String prompt,
    String apiKey,
  ) async {
    String content = "正在测试连接，请稍后...";
    showHint(content, showType: 5);
    try {
      final res = await OpenAIClientSingleton.instance.client.createChatCompletion(
          request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(model),
        messages: [
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(prompt),
          ),
        ],
      ));
      if (res.choices.isNotEmpty) {
        content = res.choices[0].message.content ?? '';
      } else {
        content = "连接成功，但是没有返回结果";
      }
    } on Exception catch (e) {
      content = "连接失败，原因是$e";
    }
    showHint(content, showType: 2);
  }

  // ====== SD相关 ======
  Future<void> testSD(String url) async {
    int showType = 5;
    String content = '测试连接中...';
    showHint(content, showType: showType);
    try {
      Response response = await myApi.testSDConnection(url);
      if (response.statusCode == 200) {
        content = '连接成功';
        showType = 2;
      } else {
        content = '连接失败，错误是${response.statusMessage}';
        showType = 3;
      }
    } catch (error) {
      content = '连接失败，错误是$error';
      showType = 3;
    }
    showHint(content, showType: showType);
  }

  Future<Map<String, dynamic>> getModels(List<String> models, String modelName) async {
    if (state.getControllerText('sd_api_url').isEmpty) return {'models': models, 'modelName': modelName};
    var settings = await Config.loadSettings();
    final defaultModel = settings['default_model'] ?? '';
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDModels(url);
      if (response.statusCode == 200) {
        models.clear();
        for (int i = 0; i < response.data.length; i++) {
          var input = response.data[i]['title'];
          int indexOfBracket = input.indexOf('['); // 查找 "[" 的索引位置
          String result = '';
          if (indexOfBracket != -1) {
            result = input.substring(0, indexOfBracket).trim();
          } else {
            result = input; // 获取 "[" 前面的子字符串，并去除前面的空格
          }
          models.add(result);
        }
      } else {
        commonPrint('获取模型列表失败1，错误是${response.statusMessage}');
      }
    } on Exception catch (e) {
      showHint('获取模型列表失败，原因是$e', showType: 3);
    }
    if (models.isNotEmpty) {
      for (int i = 0; i < models.length; i++) {
        if (models[i] == defaultModel) {
          modelName = models[i];
          break;
        }
      }
      if (modelName == "请先获取可用模型列表") {
        modelName = models[0];
      }
    }
    return {'models': models, 'modelName': modelName};
  }

  Future<Map<String, dynamic>> getSamplers(List<String> samplers, String sampler) async {
    if (state.getControllerText('sd_api_url').isEmpty) return {'samplers': samplers, 'sampler': sampler};
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDSamplers(url);
      if (response.statusCode == 200) {
        samplers.clear();
        for (int i = 0; i < response.data.length; i++) {
          samplers.add(response.data[i]['name']);
        }
      } else {
        commonPrint('获取采样器列表失败，错误是${response.statusMessage}');
        showHint('获取采样器列表失败，错误是${response.statusMessage}', showType: 3);
      }
    } catch (error) {
      commonPrint('获取采样器列表失败，错误是$error');
      showHint('获取采样器列表失败，错误是$error', showType: 3);
    }
    return {'samplers': samplers, 'sampler': sampler};
  }

  Future<Map<String, dynamic>> getLoras(List<String> loras, String loraName) async {
    if (state.getControllerText('sd_api_url').isEmpty) return {'loras': loras, 'loraName': loraName};
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDLoras(url);
      if (response.statusCode == 200) {
        loras.clear();
        loras.add('未选择lora');
        for (int i = 0; i < response.data.length; i++) {
          loras.add(response.data[i]['name']);
        }
      } else {
        commonPrint('获取Lora列表失败，错误是${response.statusMessage}');
        showHint('获取Lora列表失败，错误是${response.statusMessage}', showType: 3);
      }
    } catch (error) {
      commonPrint('获取Lora列表失败，错误是$error');
      showHint('获取Lora列表失败，错误是$error', showType: 3);
    }
    return {'loras': loras, 'loraName': loraName};
  }

  Future<Map<String, dynamic>> getVaes(List<String> vaes, String vaeName) async {
    if (state.getControllerText('sd_api_url').isEmpty) return {'vaes': vaes, 'vaeName': vaeName};
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDVaes(url);
      if (response.statusCode == 200) {
        vaes.clear();
        vaes.add("无");
        vaes.add("自动选择");
        for (int i = 0; i < response.data.length; i++) {
          vaes.add(response.data[i]['model_name']);
        }
      } else {
        commonPrint('获取VAE列表失败，错误是${response.statusMessage}');
        showHint('获取VAE列表失败，错误是${response.statusMessage}', showType: 3);
      }
    } catch (error) {
      commonPrint('获取VAE列表失败，错误是$error');
      showHint('获取VAE列表失败，错误是$error', showType: 3);
    }
    return {'vaes': vaes, 'vaeName': vaeName};
  }

  Future<Map<String, dynamic>> getUpscalers(List<String> upscalers, String upscaler) async {
    if (state.getControllerText('sd_api_url').isEmpty) return {'upscalers': upscalers, 'upscaler': upscaler};
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDUpscalers(url);
      if (response.statusCode == 200) {
        upscalers.clear();
        for (int i = 0; i < response.data.length; i++) {
          upscalers.add(response.data[i]['name']);
        }
      } else {
        commonPrint('获取超分模型列表失败，错误是${response.statusMessage}');
        showHint('获取超分模型列表失败，错误是${response.statusMessage}', showType: 3);
      }
    } catch (error) {
      commonPrint('获取超分模型列表失败，错误是$error');
      showHint('获取超分模型列表失败，错误是$error', showType: 3);
    }
    return {'upscalers': upscalers, 'upscaler': upscaler};
  }

  Future<Map<String, dynamic>> getOptions(String defaultVae, String defaultModel, String selectedVae, String selectedModel) async {
    if (state.getControllerText('sd_api_url').isEmpty) {
      return {'defaultVae': defaultVae, 'defaultModel': defaultModel, 'selectedVae': selectedVae, 'selectedModel': selectedModel};
    }
    String url = state.getControllerText('sd_api_url');
    try {
      Response response = await myApi.getSDOptions(url);
      if (response.statusCode == 200) {
        defaultVae = response.data['sd_vae'];
        defaultModel = response.data['sd_model_checkpoint'];
        int indexOfBracket = defaultModel.indexOf('['); // 查找 "[" 的索引位置
        String result = '';
        if (indexOfBracket != -1) {
          result = defaultModel.substring(0, indexOfBracket).trim();
        } else {
          result = defaultModel; // 获取 "[" 前面的子字符串，并去除前面的空格
        }

        if (defaultVae == 'Automatic') {
          defaultVae = '自动选择';
        } else if (defaultVae == 'None') {
          defaultVae = '无';
        }
        selectedVae = defaultVae;
        selectedModel = result;
      } else {
        commonPrint('获取sd设置失败，原因是${response.statusMessage}');
      }
    } catch (e) {
      commonPrint('获取sd设置失败，原因是$e');
    }
    return {'defaultVae': defaultVae, 'defaultModel': defaultModel, 'selectedVae': selectedVae, 'selectedModel': selectedModel};
  }

  // ====== Midjourney相关 ======
  Future<void> testMidjourney() async {
    showHint('测试连接中...', showType: 5);
    MyApi myApi = MyApi();
    var res = await myApi.testMJConnect();
    if (res.statusCode == 200) {
      showHint('连接成功', showType: 2);
    } else {
      showHint('连接失败，原因是${res.statusMessage}', showType: 3);
    }
  }

  Future<void> testComfyUI() async {
    String content = '测试连接中...';
    int showType = 5;
    showHint(content, showType: showType);
    try {
      Response response = await myApi.cuGetSystemStats();
      if (response.statusCode == 200) {
        content = '连接成功';
        showType = 2;
      } else {
        content = '连接失败，错误是${response.statusMessage}';
        showType = 3;
      }
    } catch (error) {
      content = '连接失败，错误是$error';
      showType = 3;
    }
    showHint(content, showType: showType);
  }

  // ====== 数据库相关 ======
  Future<void> initSupabase() async {
    try {
      var client = await SupabaseHelper().init();
      commonPrint(client);
      int showType = client != null ? 2 : 3;
      String content = client != null ? '数据库初始化成功' : '数据库初始化失败，请检查配置';
      showHint(content, showType: showType);
    } catch (e) {
      if ('$e'.contains('already initialized')) {
        showHint('数据库已经初始化了,无需再次初始化。');
      } else {
        commonPrint(e);
        showHint('数据库初始化失败，请检查配置');
      }
    }
  }

  // ====== OSS相关 ======
  Future<void> testOSS() async {
    FilePickerResult? result = await FilePickerManager().pickFiles(dialogTitle: '选择一个文件来测试oss连接');
    if (result != null) {
      showHint('正在测试文件上传到oss...', showType: 5);
      File file = File(result.files.single.path!);
      String fileType = file.path.split('.').last;
      String fileName = path.basenameWithoutExtension(file.path);
      String url = await uploadFileToALiOss(
        file.path,
        '',
        file,
        fileType: fileType,
        setFileName: fileName,
        needDelete: false,
      );
      int type = url != '' ? 2 : 3;
      commonPrint('${GlobalParams.filesUrl}$url');
      String content = url != '' ? '连接成功' : '连接失败';
      showHint(content, showType: type);
    } else {
      showHint('未选择文件无法测试oss连接');
    }
  }

  void updateVoiceMode(int mode) {
    state.updateState({'voiceSelectedMode': mode});
  }

  Future<bool> handleModelChange(String value) async {
    showHint('开始更换模型，请耐心等待更换完成', showType: 5, showTime: 2000);
    Map<String, dynamic> settings = {'default_model': value};
    await Config.saveSettings(settings);
    Map<String, dynamic> options = {'sd_model_checkpoint': value};
    Response response = await myApi.setSDOptions(state.getControllerText('sd_api_url'), options);
    String setResult = response.statusCode == 200 ? "模型更改成功，已更换为${value.split('.')[0]}模型" : "模型更改失败";
    showHint(setResult, showTime: 500);
    return response.statusCode == 200;
  }

  Future<void> handleLoraChange(String value) async {
    state.updateState({'lora': value});
  }

  Future<bool> handleVaeChange(String value) async {
    String vaeValue = value;
    if (value == '无') {
      vaeValue = 'None';
    } else if (value == '自动选择') {
      vaeValue = 'Automatic';
    }
    Map<String, dynamic> options = {'sd_vae': vaeValue};
    Response response = await myApi.setSDOptions(state.getControllerText('sd_api_url'), options);
    if (response.statusCode == 200) {
      if (vaeValue == 'None') {
        vaeValue = '无';
      } else if (vaeValue == 'Automatic') {
        vaeValue = '自动选择';
      }
      showHint("vae更改成功，已更换为${vaeValue.split('.')[0]}模型", showPosition: 2, showTime: 2);
      return true;
    } else {
      showHint("vae更改失败", showPosition: 2, showTime: 2);
      return false;
    }
  }

  Future<void> handleImagePathSelection(String path) async {
    state.updateState({'image_save_path': path});
    if (path.isNotEmpty) {
      if (containsChinese(path)) {
        showHint('文件保存路径设置失败，文件保存路径不能包含中文，请更换保存路径', showType: 3);
      } else {
        await Config.saveSettings({'image_save_path': path});
        await commonCreateDirectory(path);
        Map<String, dynamic> savedSettings = await Config.loadSettings();
        String savePath = savedSettings['image_save_path'] ?? '';
        await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
        showHint('文件保存路径设置成功', showType: 2);
      }
    } else {
      showHint('文件保存路径设置失败，文件保存路径不能为空，将使用上次的成功配置', showType: 3);
    }
  }
}
