import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_azure_tts/flutter_azure_tts.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:uuid/uuid.dart';
import '../config/config.dart';
import '../params/voice_params.dart';
import 'package:http/http.dart' as http;

import '../utils/create_ali_token.dart';
import 'common_dropdown.dart';

class VoiceTextOption extends StatefulWidget {
  final List<String> scenes;
  final DecorationImage? backgroundImage;
  final double backgroundOpacity;
  final double blurRadius;
  final Function()? onVoice;
  final String title;
  final bool isBatch;
  final int index;
  final bool isFirstStep;
  final bool? isDirectlyInto;
  final String? novelTitle;
  final int start;

  const VoiceTextOption(
      {super.key,
      required this.scenes,
      this.backgroundImage,
      this.backgroundOpacity = 1.0,
      this.blurRadius = 10.0,
      this.onVoice,
      this.title = '',
      this.isBatch = false,
      this.isFirstStep = true,
      this.novelTitle = '',
      this.isDirectlyInto = false,
      this.index = 1,
      this.start = 0});

  @override
  State<VoiceTextOption> createState() => _VoiceTextOptionState();
}

class _VoiceTextOptionState extends State<VoiceTextOption> {
  int _voiceSelectedMode = 0;
  List<String> voices = [''];
  List<String> voicesAue = [''];
  List<String> voicesEmotions = [''];
  List<String> voicesRoles = [''];
  bool isVisitable_1 = false;
  bool isVisitable_2 = false;
  bool isVisitable_3 = false;
  double _sliderValue = 0.01;
  double _speedValue = 0;
  double _pitValue = 0;
  double _volValue = 0;
  double _minSpeed = 0;
  double _maxSpeed = 0;
  double _minPit = 0;
  double _maxPit = 0;
  double _minVol = 0;
  double _maxVol = 0;
  int speedStep = 1;
  int pitStep = 1;
  int volStep = 1;
  Map<String, dynamic> envDatas = {};
  String selectedVoice = '';
  String selectedVoiceAue = '';
  String selectedVoiceEmotion = '';
  String selectedVoiceRole = '';
  Map<String, List<List<String>>> roleDict = {
    '知甜_多情感': [
      voiceParams['ali']['emotion_category']['zhitian_emo_zh'],
      voiceParams['ali']['emotion_category']['zhitian_emo_en']
    ],
    '知米_多情感': [voiceParams['ali']['emotion_category']['zhimi_emo_zh'], voiceParams['ali']['emotion_category']['zhimi_emo_en']],
    '知妙_多情感': [
      voiceParams['ali']['emotion_category']['zhimiao_emo_zh'],
      voiceParams['ali']['emotion_category']['zhimiao_emo_en']
    ],
    '知燕_多情感': [voiceParams['ali']['emotion_category']['zhiyan_emo_zh'], voiceParams['ali']['emotion_category']['zhiyan_emo_en']],
    '知贝_多情感': [voiceParams['ali']['emotion_category']['zhibei_emo_zh'], voiceParams['ali']['emotion_category']['zhibei_emo_en']]
  };

  Future<void> ttsBaidu(
      String aue, String per, double pit, double spd, String text, double vol, String voiceSaveDir, int index) async {
    var fileCount = 0;
    var isShort = true;
    var audioFormat = aue;
    var aueNumber = 0;
    var perNumber = 0;
    var machineCode = const Uuid().v4();
    var saveAudioPath = await getFileCount(voiceSaveDir, fileCount);
    fileCount = saveAudioPath['fileCount'];

    if (text.length > 60) {
      isShort = false;
    }

    if (isShort) {
      if (aue == 'mp3-16k' || aue == 'mp3-48k') {
        aue = 'mp3';
      }
    } else {
      if (aue == 'mp3') {
        aue = 'mp3-16k';
      }
    }

    for (var i = 0; i < voices.length; i++) {
      if (per == voices[i]) {
        perNumber = voiceParams['baidu']['role_number'][i];
        break;
      }
    }

    for (var i = 0; i < voiceParams['baidu']['aue'].length; i++) {
      if (aue == voiceParams['baidu']['aue'][i]) {
        aueNumber = voiceParams['baidu']['aue_num'][i];
        break;
      }
    }
    var data = {
      'grant_type': 'client_credentials',
      'client_id': envDatas['baidu_voice_api_key'],
      'client_secret': envDatas['baidu_voice_secret_key'],
    };
    Uri tokenUri = Uri.parse(voiceParams['baidu']['get_access_token_url']);
    var response = await http.post(tokenUri, body: data);
    if (response.statusCode == 200) {
      var responseDict = jsonDecode(response.body);
      var accessToken = responseDict['access_token'];
      Uri.encodeComponent(utf8.encode(text).toString());
      String encodedString1 = Uri.encodeQueryComponent(text);
      Uri.encodeQueryComponent(encodedString1);
      var headersShort = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
      };
      var headersLong = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      var ttsUrl = isShort ? voiceParams['baidu']['short_voice_url'] : voiceParams['baidu']['long_voice_create_url'];
      var payload = {};
      if (isShort) {
        payload = {
          "lan": "zh",
          "tex": text,
          "tok": accessToken,
          "cuid": machineCode,
          "ctp": 1,
          "spd": spd.toInt(),
          "pit": pit.toInt(),
          "vol": vol.toInt(),
          "per": perNumber,
          "aue": aueNumber,
        };
      } else {
        payload = {
          "lang": "zh",
          "text": text,
          "format": audioFormat,
          "voice": perNumber,
          "speed": spd.toInt(),
          "pitch": pit.toInt(),
          "volume": vol.toInt(),
        };
      }
      http.Response response1;
      if (!isShort) {
        ttsUrl = '$ttsUrl?access_token=$accessToken';
        Uri ttsUri = Uri.parse(ttsUrl);
        response1 = await http.post(ttsUri, headers: headersLong, body: jsonEncode(payload));
      } else {
        // 将整数值转换为字符串后再进行编码
        Map<String, String> data = Map.from(payload).map((key, value) => MapEntry(key, value.toString()));
        // 将参数编码为URL编码格式
        String formData = data.keys.map((key) => '$key=${Uri.encodeQueryComponent(data[key]!)}').join('&');
        Uri ttsUri = Uri.parse(ttsUrl);
        response1 = await http.post(ttsUri, headers: headersShort, body: formData);
      }
      if (!isShort) {
        if (response1.statusCode == 200) {
          var responseDict = jsonDecode(response1.body);
          if (responseDict.containsKey('error_code')) {
            if (mounted) {
              showHint('百度长文本转语音任务创建失败，错误原因： ${responseDict['error_msg']}');
            }
          } else if (responseDict.containsKey('error')) {
            if (mounted) {
              showHint('百度长文本转语音任务创建失败，错误原因： ${responseDict['error']}---${responseDict['message']}');
            }
          } else {
            var taskId = responseDict['task_id'];
            var payload = jsonEncode({
              'task_ids': ['$taskId'],
            });
            while (true) {
              Uri uri = Uri.parse('${voiceParams['baidu']['long_voice_query_url']}?access_token=$accessToken');
              var response2 = await http.post(uri, headers: headersLong, body: payload);
              var rj = jsonDecode(response2.body);
              if (response2.statusCode == 200) {
                if (rj['tasks_info'][0]['task_status'] == 'Success') {
                  var speechUrl = rj['tasks_info'][0]['task_result']['speech_url'];
                  var response3 = await http.get(speechUrl);
                  var fileExt = audioFormat;
                  if (audioFormat == 'pcm-8k' || audioFormat == 'pcm-16k') {
                    fileExt = 'pcm';
                  } else if (audioFormat == 'mp3-16k' || audioFormat == 'mp3-48k') {
                    fileExt = 'mp3';
                  }

                  var fileDir = saveAudioPath['path'];
                  var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
                  await file.writeAsBytes(response3.bodyBytes);
                  break;
                } else if (rj['tasks_info'][0]['task_status'] == 'Running') {
                  await Future.delayed(const Duration(seconds: 10));
                } else if (rj['tasks_info'][0]['task_status'] == 'Failure') {
                  if (mounted) {
                    showHint('百度长文本合成语音失败，原因是-----> ${rj['tasks_info'][0]['task_result']['err_msg']}');
                  }
                  break;
                }
              } else {
                break;
              }
            }
          }
        }
      }

      var fileExtDict = {
        3: 'mp3',
        4: 'pcm',
        5: 'pcm',
        6: 'wav',
      };

      var contentTypeDict = {
        3: 'audio/mp3',
        4: 'audio/basic;codec=pcm;rate=16000;channel=1',
        5: 'audio/basic;codec=pcm;rate=8000;channel=1',
        6: 'audio/wav',
      };

      if (isShort) {
        var contentType = response1.headers['content-type'];
        if (fileExtDict.containsKey(aueNumber) && contentType == contentTypeDict[aueNumber]) {
          var fileExt = fileExtDict[aueNumber];
          var fileDir = saveAudioPath['path'];
          var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
          await file.writeAsBytes(response1.bodyBytes);
        } else {
          if (mounted) {
            showHint('百度短文本语音合成失败，请稍后重试。错误代码是${response1.statusCode},返回结果头部信息为${response1.headers}');
          }
        }
      }
    } else {
      if (mounted) {
        showHint('百度语音合成请求失败，请稍后重试。错误代码是${response.statusCode}原因是${response.body}');
      }
    }
  }

  Future<void> downloadAudio(String appKey, String token, String taskId, String ttsUrl, Map<String, String> headers, String aue,
      String voiceSaveDir, int fileCount, String saveAudioPath, int index) async {
    while (true) {
      Map<String, String> data = {
        'appkey': appKey,
        'token': token,
        'task_id': taskId,
      };
      Uri uri = Uri.parse(ttsUrl).replace(queryParameters: data);
      http.Response response = await http.get(uri, headers: headers);
      Map<String, dynamic> rj = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (rj["data"]["audio_address"] != null) {
          String speechUrl = rj["data"]["audio_address"];
          http.Response response2 = await http.get(Uri.parse(speechUrl));
          String fileExt = aue;
          var fileDir = saveAudioPath;
          var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
          await file.writeAsBytes(response2.bodyBytes);
          break;
        } else {
          await Future.delayed(const Duration(seconds: 10));
        }
      } else {
        if (mounted) {
          showHint('阿里长文本合成语音失败，原因是----->${rj['error_message']}');
        }
        break;
      }
    }
  }

  Future<void> ttsAli(String voiceSaveDir, String text, String per, String voiceEmotion, double voiceEmotionIntensity, String aue,
      double vol, double spd, double pit, int index) async {
    String accessKeyId = envDatas['ali_voice_access_id'];
    String accessKeySecret = envDatas['ali_voice_access_secret'];
    List<String> args = [accessKeyId, accessKeySecret];
    String aliToken = getAliToken(args);
    bool isShort = true;
    var machineCode = const Uuid().v4();
    var fileCount = 0;
    var ttsUrl = '';
    var appKey = envDatas['ali_voice_app_key'];
    var headers = {'Content-Type': 'application/json', 'Accept': '*/*'};
    var saveAudioPath = await getFileCount(voiceSaveDir, fileCount);
    fileCount = saveAudioPath['fileCount'];
    if (text.length > 100) {
      isShort = false;
    }
    if (isShort) {
      ttsUrl = voiceParams['ali']['short_voice_url'];
    } else {
      ttsUrl = voiceParams['ali']['long_voice_url'];
    }
    for (int i = 0; i < voiceParams['ali']['voice_role'].length; i++) {
      String role = voiceParams['ali']['voice_role'][i];
      if (per == role) {
        if (role.contains('多情感')) {
          for (String key in roleDict.keys) {
            if (role.contains(key)) {
              List<List<String>> emos = roleDict[key]!;
              for (int j = 0; j < emos[0].length; j++) {
                String emo = emos[0][j];
                if (emo == voiceEmotion) {
                  String emoType = emos[1][j];
                  text = '<speak><emotion category="$emoType" intensity="$voiceEmotionIntensity">$text</emotion></speak>';
                }
              }
            }
          }
        }
        per = voiceParams['ali']['voice_code'][i];
      }
    }

    if (aliToken != '') {
      // 短文本请求的payload
      String shortPayload = jsonEncode({
        'text': text,
        'appkey': appKey,
        'token': aliToken,
        'format': aue,
        'voice': per,
        'volume': vol.toInt(),
        'speech_rate': spd.toInt(),
        'pitch_rate': pit.toInt()
      });

      // 长文本请求的payload
      String longPayload = jsonEncode({
        "payload": {
          "tts_request": {
            "voice": per,
            "sample_rate": 16000,
            "format": aue,
            "text": text,
            "enable_subtitle": false,
            'volume': vol.toInt(),
            'speech_rate': spd.toInt(),
            'pitch_rate': pit.toInt()
          },
          "enable_notify": false
        },
        "context": {"device_id": machineCode},
        "header": {"appkey": appKey, "token": aliToken}
      });
      String data = isShort ? shortPayload : longPayload;

      http.Response response = await http.post(
        Uri.parse(ttsUrl),
        headers: headers,
        body: utf8.encode(data),
      );
      if (isShort) {
        if (response.statusCode == 200) {
          String contentType = response.headers['content-type']!;
          commonPrint('返回值头是${response.headers}');
          if (contentType == 'audio/mpeg') {
            String fileExt = aue;
            var fileDir = saveAudioPath['path'];
            var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
            await file.writeAsBytes(response.bodyBytes);
          } else if (contentType == 'application/json') {
            if (mounted) {
              showHint("语音合成失败，错误原因是:----->${response.body}");
            }
          }
        } else {
          if (mounted) {
            showHint("语音合成失败，错误原因是:----->${response.body}");
          }
        }
      } else {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (response.statusCode == 200) {
          String taskId = responseJson['data']['task_id'];
          downloadAudio(appKey, aliToken, taskId, ttsUrl, headers, aue, voiceSaveDir, fileCount, saveAudioPath['path'], index);
        } else {
          if (mounted) {
            showHint('阿里长文本转语音任务创建失败，原因是:----->${responseJson['message']}');
          }
        }
      }
    } else {
      if (mounted) {
        showHint('阿里鉴权失败，请稍后重试。');
      }
    }
  }

  Future<void> ttsHuawei(
      String text, String aue, String per, double pit, double spd, double vol, String voiceSaveDir, int index) async {
    if (text.length > 100) {
      if (mounted) {
        showHint('文本过长,目前华为语音API每次仅支持100字以内的文字转语音');
      }
    } else {
      var fileCount = 0;
      var saveAudioPath = await getFileCount(voiceSaveDir, fileCount);
      fileCount = saveAudioPath['fileCount'];
      var getAccessTokenUrl = voiceParams['huawei']['get_access_token_url'];
      var ttsUrl = voiceParams['huawei']['tts_url'];
      Map<String, dynamic> getAccessTokenPayload = {
        "auth": {
          "identity": {
            "methods": ["hw_ak_sk"],
            "hw_ak_sk": {
              "access": {
                "key": envDatas['huawei_voice_ak'],
              },
              "secret": {
                "key": envDatas['huawei_voice_sk'],
              },
            },
          },
          "scope": {
            "project": {
              "name": "cn-east-3",
            },
          },
        },
      };

      String getAccessTokenPayloadJson = jsonEncode(getAccessTokenPayload);
      var tokenHeaders = {'Content-Type': 'application/json'};
      for (int i = 0; i < voiceParams['huawei']['voice_role'].length; i++) {
        String role = voiceParams['huawei']['voice_role'][i];
        if (per == role) {
          per = voiceParams['huawei']['voice_code'][i];
        }
      }
      http.Response response = await http.post(
        Uri.parse(getAccessTokenUrl),
        headers: tokenHeaders,
        body: getAccessTokenPayloadJson,
      );
      var token = response.headers["x-subject-token"];
      if (token != null && token != "") {
        commonPrint('华为鉴权成功');
        var ttsHeaders = {
          'X-Auth-Token': token,
          'Content-Type': 'application/json',
        };

        var ttsPayload = {
          'text': text,
          'config': {
            'audio_format': aue,
            'sample_rate': '16000',
            'property': per,
            'speed': spd,
            'pitch': pit,
            'volume': vol,
          },
        };
        String ttsPayloadJson = jsonEncode(ttsPayload);
        Uri uriUrl = Uri.parse(ttsUrl);
        http.Response responseTts = await http.post(uriUrl, headers: ttsHeaders, body: ttsPayloadJson);
        var rj = jsonDecode(responseTts.body);
        if (responseTts.statusCode == 200) {
          var data = rj['result']['data'];
          var audioData = base64Decode(data);
          var fileExt = aue;
          var fileDir = saveAudioPath['path'];
          var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
          if (fileExt == 'mp3') {
            file.writeAsBytesSync(audioData);
          } else {
            int sampleRate = 16000;
            int bitsPerSample = 16;
            int channels = 1;

            int byteRate = sampleRate * bitsPerSample ~/ 8;
            int blockAlign = bitsPerSample ~/ 8 * channels;

            int subChunk2Size = audioData.length;
            int chunkSize = 36 + subChunk2Size;

            // WAV文件头部信息
            Uint8List wavHeader = Uint8List.fromList([
              // RIFF标识符
              82,
              73,
              70,
              70,
              chunkSize & 0xFF,
              (chunkSize >> 8) & 0xFF,
              (chunkSize >> 16) & 0xFF,
              (chunkSize >> 24) & 0xFF,
              // WAVE格式标志
              87,
              65,
              86,
              69,
              // fmt子块
              102,
              109,
              116,
              32,
              16,
              0,
              0,
              0,
              // 子块大小
              1,
              0,
              // 音频格式（1表示PCM）
              channels & 0xFF,
              (channels >> 8) & 0xFF,
              // 声道数
              sampleRate & 0xFF,
              (sampleRate >> 8) & 0xFF,
              (sampleRate >> 16) & 0xFF,
              (sampleRate >> 24) & 0xFF,
              // 采样率
              byteRate & 0xFF,
              (byteRate >> 8) & 0xFF,
              (byteRate >> 16) & 0xFF,
              (byteRate >> 24) & 0xFF,
              // 数据传输速率
              blockAlign & 0xFF,
              (blockAlign >> 8) & 0xFF,
              // 数据块对齐单位
              bitsPerSample & 0xFF,
              (bitsPerSample >> 8) & 0xFF,
              // 位深度
              // data子块
              100,
              97,
              116,
              97,
              subChunk2Size & 0xFF,
              (subChunk2Size >> 8) & 0xFF,
              (subChunk2Size >> 16) & 0xFF,
              (subChunk2Size >> 24) & 0xFF,
            ]);
            file.writeAsBytesSync(Uint8List.fromList(wavHeader + audioData));
          }
        } else {
          if (mounted) {
            showHint("华为语音合成失败，原因是----->, ${rj['error_msg']}");
          }
        }
      } else {
        if (mounted) {
          showHint('华为鉴权失败,请重试');
        }
      }
    }
  }

  Future<void> ttsAzure(String text, double spd, double pit, double vol, String per, String aue, String voiceEmotion,
      double voiceEmotionIntensity, String voiceRolePlay, String voiceSaveDir, int index) async {
    var pits = ['x-low', 'low', 'default', 'medium', 'high', 'x-high'];
    var realPit = pits[pit.toInt() - 1];
    var fileCount = 0;
    var fileExt = aue;
    var audioFormat = AudioOutputFormat.audio48khz192kBitrateMonoMp3;
    var saveAudioPath = await getFileCount(voiceSaveDir, fileCount);
    fileCount = saveAudioPath['fileCount'];
    var voiceName = '';
    var voiceStyle = '';
    var voiceRole = '';
    for (int i = 0; i < voiceParams['azure']['voice_role'].length; i++) {
      var voiceRoleName = voiceParams['azure']['voice_role'][i];
      if (per == voiceRoleName) {
        voiceName = voiceParams['azure']['voice_code'][i];
      }
    }
    if (per.contains('多情感')) {
      for (var key in voiceParams['azure']['emotion_category'].keys) {
        if (voiceName.contains(key)) {
          for (int i = 0; i < voiceParams['azure']['emotion_category'][key]['styles_zh'].length; i++) {
            var style = voiceParams['azure']['emotion_category'][key]['styles_zh'][i];
            if (voiceEmotion == style) {
              voiceStyle = voiceParams['azure']['emotion_category'][key]['styles_en'][i];
            }
          }
          if (voiceParams['azure']['emotion_category'][key].containsKey('roles_en')) {
            for (int i = 0; i < voiceParams['azure']['emotion_category'][key]['roles_zh'].length; i++) {
              var role = voiceParams['azure']['emotion_category'][key]['roles_zh'][i];
              if (voiceRolePlay == role) {
                voiceRole = voiceParams['azure']['emotion_category'][key]['roles_en'][i];
              }
            }
          }
        }
      }
    }
    try {
      final voicesResponse = await AzureTts.getAvailableVoices();
      final voices = voicesResponse.voices;
      late Voice selectedVoice;
      for (var voice in voices) {
        if (per.contains(voice.localName)) {
          if (per.contains('四川话')) {
            // 这里的判断是因为微软的语音库里面云希有两个语音版本一个普通话，一个四川话
            if (voice.shortName == 'zh-CN-sichuan-YunxiNeural') {
              selectedVoice = voice;
              break;
            }
          } else if (per.contains('拟真')) {
            if (voice.shortName.contains('MultilingualNeural')) {
              selectedVoice = voice;
              break;
            }
          } else {
            selectedVoice = voice;
            break;
          }
        }
      }
      TtsParams ttsParams = TtsParams(
          voice: selectedVoice,
          audioFormat: audioFormat,
          text: text,
          rate: spd,
          pitch: realPit,
          volume: vol,
          emo: voiceStyle,
          emoSrc: voiceEmotionIntensity,
          rolePlay: voiceRole);
      final ttsResponse = await AzureTts.getTts(ttsParams);
      final audioBytes = ttsResponse.audio.buffer.asUint8List();
      var fileDir = saveAudioPath['path'];
      var file = File('$fileDir${Platform.pathSeparator}scene${index + 1}.$fileExt');
      file.writeAsBytesSync(audioBytes);
    } catch (e) {
      commonPrint('$e');
    }
  }

  Future<Map<String, dynamic>> getFileCount(String voiceSaveDir, int fileCount) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String? defaultFolder = settings['current_novel_folder'];
    if (defaultFolder == null || defaultFolder == '') {
      defaultFolder = settings['image_save_path'];
    }
    String saveDate = '';
    if (widget.isDirectlyInto!) {
      saveDate = widget.novelTitle!.split('_')[1];
    } else {
      saveDate = currentDayStr();
    }
    var saveAudioPath = '';
    if (voiceSaveDir.isEmpty) {
      saveAudioPath = "$defaultFolder/audio/$saveDate";
    } else {
      saveAudioPath = "$voiceSaveDir/audio/$saveDate";
    }
    Directory directory = Directory(saveAudioPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    if (voiceSaveDir.isEmpty) {
      for (var entry in Directory(saveAudioPath).listSync()) {
        if (entry is File) {
          fileCount++;
        }
      }
    } else {
      for (var entry in Directory(voiceSaveDir).listSync()) {
        if (entry is File) {
          fileCount++;
        }
      }
    }
    // 使用Map包装返回的值
    Map<String, dynamic> data = {
      'fileCount': fileCount,
      'path': saveAudioPath,
    };
    return data;
  }

  void changeVoiceRole(String role) {
    if (_voiceSelectedMode == 1) {
      if (role.contains('多情感')) {
        for (String key in roleDict.keys) {
          if (role.contains(key)) {
            List<List<String>>? emotions = roleDict[key];
            if (emotions != null) {
              setState(() {
                isVisitable_1 = true;
                isVisitable_2 = true;
                voicesEmotions = emotions[0];
                selectedVoiceEmotion = voicesEmotions[0];
              });
            }
            break;
          }
        }
      } else {
        setState(() {
          isVisitable_1 = false;
          isVisitable_2 = false;
        });
      }
    } else if (_voiceSelectedMode == 3) {
      String roleCode = '';
      for (int i = 0; i < voiceParams['azure']['voice_role'].length; i++) {
        if (role == voiceParams['azure']['voice_role'][i]) {
          roleCode = voiceParams['azure']['voice_code'][i];
          break;
        }
      }
      if (role.contains('多情感')) {
        for (String key in voiceParams['azure']['emotion_category'].keys) {
          if (roleCode.contains(key)) {
            if (voiceParams['azure']['emotion_category'][key].keys.contains('roles_en')) {
              setState(() {
                isVisitable_1 = true;
                isVisitable_2 = true;
                isVisitable_3 = true;
                voicesEmotions = voiceParams['azure']['emotion_category'][key]['styles_zh'];
                selectedVoiceEmotion = voicesEmotions[0];
                voicesRoles = voiceParams['azure']['emotion_category'][key]['roles_zh'];
                selectedVoiceRole = voicesRoles[0];
              });
            } else {
              setState(() {
                isVisitable_1 = true;
                isVisitable_2 = true;
                isVisitable_3 = false;
                voicesEmotions = voiceParams['azure']['emotion_category'][key]['styles_zh'];
                selectedVoiceEmotion = voicesEmotions[0];
              });
            }
            break;
          }
        }
      } else {
        setState(() {
          isVisitable_1 = false;
          isVisitable_2 = false;
          isVisitable_3 = false;
        });
      }
    }
  }

  void changeVoice() {
    if (_voiceSelectedMode == 0) {
      setState(() {
        isVisitable_1 = false;
        isVisitable_2 = false;
        isVisitable_3 = false;
        _minSpeed = 0;
        _maxSpeed = 9;
        _minPit = 0;
        _maxPit = 9;
        _minVol = 0;
        _maxVol = 15;
        _speedValue = 5;
        _pitValue = 5;
        _volValue = 5;
        speedStep = 10;
        pitStep = 10;
        volStep = 16;
      });
    } else if (_voiceSelectedMode == 1) {
      setState(() {
        isVisitable_1 = true;
        isVisitable_2 = true;
        isVisitable_3 = false;
        _sliderValue = 1;
        _minSpeed = -500;
        _maxSpeed = 500;
        _minPit = -500;
        _maxPit = 500;
        _minVol = 0;
        _maxVol = 100;
        _speedValue = 0;
        _pitValue = 0;
        _volValue = 50;
        speedStep = 10;
        pitStep = 10;
        volStep = 10;
      });
    } else if (_voiceSelectedMode == 2) {
      setState(() {
        isVisitable_1 = false;
        isVisitable_2 = false;
        isVisitable_3 = false;
        _minSpeed = -500;
        _maxSpeed = 500;
        _minPit = -500;
        _maxPit = 500;
        _minVol = 0;
        _maxVol = 100;
        _speedValue = 0;
        _pitValue = 0;
        _volValue = 50;
        speedStep = 10;
        pitStep = 10;
        volStep = 10;
      });
    } else if (_voiceSelectedMode == 3) {
      setState(() {
        isVisitable_1 = false;
        isVisitable_2 = false;
        isVisitable_3 = false;
        _sliderValue = 1;
        _minSpeed = 0.5;
        _maxSpeed = 2;
        _minPit = 1;
        _maxPit = 6;
        _minVol = 0;
        _maxVol = 100;
        _speedValue = 1;
        _pitValue = 3;
        _volValue = 100;
        speedStep = 15;
        pitStep = 6;
        volStep = 20;
      });
    }
  }

  Future<void> loadSettings() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    envDatas = settings;
    try {
      var speechKey = envDatas['azure_voice_speech_key'];
      var serviceRegion = "eastus";
      if (speechKey != null && speechKey != "") {
        bool? isInitialized = envDatas['azure_initialized'];
        if (isInitialized != null && !isInitialized) {
          AzureTts.init(subscriptionKey: speechKey, region: serviceRegion, withLogs: true);
        }
        Map<String, dynamic> azureInitialized = {
          'azure_initialized': true,
        };
        await Config.saveSettings(azureInitialized);
      }
    } catch (e) {
      if (mounted) {
        showHint('$e');
      }
      Map<String, dynamic> azureInitialized = {
        'azure_initialized': false,
      };
      await Config.saveSettings(azureInitialized);
    }
    int? useVoiceMode = settings['use_voice_mode'];
    if (useVoiceMode != null) {
      setState(() {
        _voiceSelectedMode = useVoiceMode;
        if (useVoiceMode == 0) {
          voices = voiceParams['baidu']['voice_role'];
          voicesAue = voiceParams['baidu']['aue'];
        } else if (useVoiceMode == 1) {
          voices = voiceParams['ali']['voice_role'];
          voicesAue = voiceParams['ali']['aue'];
        } else if (useVoiceMode == 2) {
          voices = voiceParams['huawei']['voice_role'];
          voicesAue = voiceParams['huawei']['aue'];
        } else if (useVoiceMode == 3) {
          voices = voiceParams['azure']['voice_role'];
          voicesAue = voiceParams['azure']['aue'];
        }
        selectedVoice = voices[0];
        selectedVoiceAue = voicesAue[0];
        changeVoice();
      });
    }
  }

  void onChangeVoice(String voice) {
    selectedVoice = voice;
    changeVoiceRole(voice);
  }

  void onChangeVoiceAue(String voiceAue) {
    selectedVoiceAue = voiceAue;
  }

  void onChangeVoiceEmotion(String voiceEmotion) {
    selectedVoiceEmotion = voiceEmotion;
  }

  void onChangeVoiceRole(String voiceRole) {
    selectedVoiceRole = voiceRole;
  }

  @override
  void initState() {
    loadSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 920,
      height: 300,
      child: Stack(children: [
        if (widget.backgroundImage != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: widget.backgroundImage,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: widget.blurRadius, sigmaY: widget.blurRadius),
                child: Container(
                  color: Colors.black.withAlpha((widget.backgroundOpacity*255).toInt()),
                ),
              ),
            ),
          ),
        Column(
          children: [
            Center(
                child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 28),
            )),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  '文本配音引擎:',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text(
                      '百度语音',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 0,
                    groupValue: _voiceSelectedMode,
                    onChanged: (value) async {
                      setState(() {
                        _voiceSelectedMode = value!;
                        voices = voiceParams['baidu']['voice_role'];
                        selectedVoice = voices[0];
                        voicesAue = voiceParams['baidu']['aue'];
                        selectedVoiceAue = voicesAue[0];
                        changeVoice();
                        changeVoiceRole(selectedVoice);
                      });
                    },
                    activeColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text(
                      '阿里语音',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 1,
                    groupValue: _voiceSelectedMode,
                    onChanged: (value) async {
                      setState(() {
                        _voiceSelectedMode = value!;
                        voices = voiceParams['ali']['voice_role'];
                        selectedVoice = voices[0];
                        voicesAue = voiceParams['ali']['aue'];
                        selectedVoiceAue = voicesAue[0];
                        changeVoice();
                        changeVoiceRole(selectedVoice);
                      });
                    },
                    activeColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text(
                      '华为语音',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 2,
                    groupValue: _voiceSelectedMode,
                    onChanged: (value) async {
                      setState(() {
                        _voiceSelectedMode = value!;
                        voices = voiceParams['huawei']['voice_role'];
                        selectedVoice = voices[0];
                        voicesAue = voiceParams['huawei']['aue'];
                        selectedVoiceAue = voicesAue[0];
                        changeVoice();
                        changeVoiceRole(selectedVoice);
                      });
                    },
                    activeColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text(
                      '微软语音',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 3,
                    groupValue: _voiceSelectedMode,
                    onChanged: (value) async {
                      setState(() {
                        _voiceSelectedMode = value!;
                        voices = voiceParams['azure']['voice_role'];
                        selectedVoice = voices[0];
                        voicesAue = voiceParams['azure']['aue'];
                        selectedVoiceAue = voicesAue[0];
                        changeVoice();
                        changeVoiceRole(selectedVoice);
                      });
                    },
                    activeColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: <Widget>[
                const Text(
                  '语音角色:',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonDropdownWidget(
                    dropdownData: voices,
                    selectedValue: selectedVoice,
                    onChangeValue: onChangeVoice,
                  ),
                ),
                Visibility(
                    visible: false,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Text(
                          '保存语音文件格式:',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 160,
                          child: CommonDropdownWidget(
                            dropdownData: voicesAue,
                            selectedValue: selectedVoiceAue,
                            onChangeValue: onChangeVoiceAue,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: <Widget>[
                Visibility(
                    visible: isVisitable_1,
                    child: Expanded(
                      child: Row(children: <Widget>[
                        const Text(
                          '情感类型:',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CommonDropdownWidget(
                            dropdownData: voicesEmotions,
                            selectedValue: selectedVoiceEmotion,
                            onChangeValue: onChangeVoiceEmotion,
                          ),
                        ),
                      ]),
                    )),
                Visibility(
                    visible: isVisitable_2,
                    child: Expanded(
                      child: Row(
                        children: <Widget>[
                          const SizedBox(width: 10),
                          Text(
                            '情感强度:(${_sliderValue.toStringAsFixed(2)})',
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          Expanded(
                            child: Slider(
                              value: _sliderValue,
                              min: 0.01,
                              max: 2.00,
                              divisions: 200,
                              onChanged: (value) {
                                setState(() {
                                  _sliderValue = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )),
                Visibility(
                    visible: isVisitable_3,
                    child: Expanded(
                      child: Row(
                        children: <Widget>[
                          const Text(
                            '角色扮演:',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CommonDropdownWidget(
                              dropdownData: voicesRoles,
                              selectedValue: selectedVoiceRole,
                              onChangeValue: onChangeVoiceRole,
                            ),
                            // DropdownButton(
                            //   value: selectedVoiceRole, // 设置选中值
                            //   dropdownColor: const Color.fromARGB(255, 202, 191, 250),
                            //   items: voicesRoles.map<DropdownMenuItem<String>>((String value) {
                            //     return DropdownMenuItem<String>(
                            //       value: value,
                            //       child: Text(
                            //         value,
                            //         style: const TextStyle(color: Colors.white, fontSize: 20),
                            //       ),
                            //     );
                            //   }).toList(),
                            //   onChanged: (String? newValue) async {
                            //     setState(() {
                            //       selectedVoiceRole = newValue!;
                            //     });
                            //   },
                            // ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: <Widget>[
                Visibility(
                    child: Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        '语速:(${_speedValue.toStringAsFixed(1)})',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Expanded(
                        child: Slider(
                          value: _speedValue,
                          min: _minSpeed,
                          max: _maxSpeed,
                          divisions: speedStep,
                          onChanged: (value) {
                            setState(() {
                              _speedValue = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )),
                Visibility(
                    child: Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        '语调:(${_pitValue.toStringAsFixed(0)})',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Expanded(
                        child: Slider(
                          value: _pitValue,
                          min: _minPit,
                          max: _maxPit,
                          divisions: pitStep,
                          onChanged: (value) {
                            setState(() {
                              _pitValue = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )),
                Visibility(
                    child: Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        '音量:(${_volValue.toStringAsFixed(0)})',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Expanded(
                        child: Slider(
                          value: _volValue,
                          min: _minVol,
                          max: _maxVol,
                          divisions: volStep,
                          onChanged: (value) {
                            setState(() {
                              _volValue = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 920,
                  child: ElevatedButton(
                      onPressed: () async {
                        if (widget.isBatch) {
                          for (int i = widget.start; i < widget.scenes.length; i++) {
                            showHint('第${i + 1}个场景的语音生成中...', showType: 5);
                            if (_voiceSelectedMode == 0) {
                              await ttsBaidu(
                                  selectedVoiceAue, selectedVoice, _pitValue, _speedValue, widget.scenes[i], _volValue, '', i);
                            } else if (_voiceSelectedMode == 1) {
                              await ttsAli('', widget.scenes[i], selectedVoice, selectedVoiceEmotion, _sliderValue,
                                  selectedVoiceAue, _volValue, _speedValue, _pitValue, i);
                            } else if (_voiceSelectedMode == 2) {
                              await ttsHuawei(
                                  widget.scenes[i], selectedVoiceAue, selectedVoice, _pitValue, _speedValue, _volValue, '', i);
                            } else if (_voiceSelectedMode == 3) {
                              await ttsAzure(widget.scenes[i], _speedValue, _pitValue, _volValue, selectedVoice, selectedVoiceAue,
                                  selectedVoiceEmotion, _sliderValue, selectedVoiceRole, '', i);
                            }
                            dismissHint();
                          }
                        } else {
                          showHint('语音生成中...', showType: 5);
                          if (_voiceSelectedMode == 0) {
                            await ttsBaidu(selectedVoiceAue, selectedVoice, _pitValue, _speedValue, widget.scenes[0], _volValue,
                                '', widget.index);
                          } else if (_voiceSelectedMode == 1) {
                            await ttsAli('', widget.scenes[0], selectedVoice, selectedVoiceEmotion, _sliderValue,
                                selectedVoiceAue, _volValue, _speedValue, _pitValue, widget.index);
                          } else if (_voiceSelectedMode == 2) {
                            await ttsHuawei(widget.scenes[0], selectedVoiceAue, selectedVoice, _pitValue, _speedValue, _volValue,
                                '', widget.index);
                          } else if (_voiceSelectedMode == 3) {
                            await ttsAzure(widget.scenes[0], _speedValue, _pitValue, _volValue, selectedVoice, selectedVoiceAue,
                                selectedVoiceEmotion, _sliderValue, selectedVoiceRole, '', widget.index);
                          }
                          dismissHint();
                        }
                        widget.onVoice!();
                      },
                      child: const Text('文本转音频')),
                ),
              ),
            ),
          ],
        )
      ]),
    );
  }
}
