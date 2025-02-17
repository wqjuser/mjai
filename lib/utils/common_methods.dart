import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart' as alioss;
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart' as dio;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/utils/native_screen_utils.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:yaml/yaml.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:process_run/process_run.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as path;
import '../config/config.dart';
import '../net/my_api.dart';
import 'log_manager_old.dart';

void commonPrint(dynamic message) {
  // LoggerHelper.info(message);
  LogManagerOld().logAny(message);
}

void showHint(String message,
    {BuildContext? context, int showTime = 2000, int showPosition = 2, List<Widget>? actions, bool isFloating = true, int showType = 1}) {
  if (showType == 5) {
    //显示长时间的提示
    EasyLoading.show(status: message, dismissOnTap: true);
  } else if (showType == 4) {
    var toastPosition = EasyLoadingToastPosition.top;
    //显示toast
    switch (showPosition) {
      case 1:
        //上
        toastPosition = EasyLoadingToastPosition.top;
        break;
      case 2:
        toastPosition = EasyLoadingToastPosition.center;
        break;
      case 3:
        //下
        toastPosition = EasyLoadingToastPosition.bottom;
        break;
    }
    EasyLoading.showToast(message, toastPosition: toastPosition, duration: Duration(milliseconds: showTime), dismissOnTap: true);
  } else if (showType == 2) {
    //成功信息提示
    EasyLoading.showSuccess(message, duration: Duration(milliseconds: showTime), dismissOnTap: true);
  } else if (showType == 3) {
    //错误信息提示
    EasyLoading.showError(message, duration: Duration(milliseconds: showTime), dismissOnTap: true);
  } else {
    //普通信息提示
    EasyLoading.showInfo(message, duration: Duration(milliseconds: showTime), dismissOnTap: true);
  }
}

void dismissHint() {
  if (EasyLoading.isShow) {
    EasyLoading.dismiss();
  }
}

Future<String> imageToBase64(String imagePath) async {
  File imageFile = File(imagePath);
  List<int> imageBytes = await imageFile.readAsBytes();
  String base64String = base64Encode(imageBytes);
  return base64String;
}

Future<String> b64ImgFromPath(String imagePath) async {
  final ui.Image image = await loadImage(imagePath);
  return "data:image/png;base64,${await rawB64Img(image)}";
}

Future<String> rawB64Img(ui.Image image) async {
  final rawImageData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = rawImageData!.buffer.asUint8List();

  final imgLibImage = img.decodeImage(Uint8List.fromList(pngBytes))!;
  final encodedImage = imgLibImage.getBytes();

  return base64.encode(encodedImage);
}

Future<ui.Image> loadImage(String imagePath) async {
  final ByteData data = await rootBundle.load(imagePath);
  final Completer<ui.Image> completer = Completer();

  ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
    return completer.complete(img);
  });

  return completer.future;
}

Future<String> compressBase64Image(String base64Image, [int quality = 80, double scale = 0.5]) async {
  bool isShowing = false;
  if (!EasyLoading.isShow) {
    isShowing = true;
    showHint('图片压缩中...', showType: 5);
  }
  try {
    // 将Base64字符串解码成Uint8List
    Uint8List uint8List = base64Decode(base64Image);
    // 解码成图像
    img.Image image = img.decodeImage(uint8List)!;
    // 计算缩放后的宽高
    int newWidth = (image.width * scale).round();
    int newHeight = (image.height * scale).round();
    // 压缩图像数据
    img.Image compressedImage = img.copyResize(image, width: newWidth, height: newHeight, interpolation: img.Interpolation.linear);
    // 将压缩后的图像编码为Uint8List
    Uint8List compressedData = Uint8List.fromList(img.encodeJpg(compressedImage, quality: quality));

    // 将压缩后的数据转换为Base64字符串
    String compressedBase64 = base64Encode(compressedData);
    if (EasyLoading.isShow) {
      if (isShowing) {
        EasyLoading.dismiss();
      }
    }
    return compressedBase64;
  } catch (e) {
    commonPrint('压缩图片出错：$e');
    if (EasyLoading.isShow) {
      if (isShowing) {
        EasyLoading.dismiss();
      }
    }
    return base64Image; // 如果出现错误，返回原始Base64编码的图片
  }
}

String removeMultipleEmptyLines(String input, int maxEmptyLines) {
  List<String> lines = input.split('\n');
  List<String> nonEmptyLines = [];
  int emptyLineCount = 0;

  for (String line in lines) {
    if (line.trim().isNotEmpty) {
      nonEmptyLines.add(line);
      emptyLineCount = 0;
    } else {
      emptyLineCount++;
      if (emptyLineCount <= maxEmptyLines) {
        nonEmptyLines.add(line);
      }
    }
  }

  return nonEmptyLines.join('\n');
}

String currentDayStr({bool needTime = false, bool needMillSeconds = false}) {
  DateTime currentDate = DateTime.now();
  String time = '${currentDate.hour}-${currentDate.minute}-${currentDate.second}';
  if (needMillSeconds) {
    time = '$time-${currentDate.millisecond}';
  }
  String day = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
  return needTime ? '$day-$time' : day;
}

Future<void> commonCreateDirectory(String userPath) async {
  final path = userPath;
  final directory = Directory(path);
  if (await directory.exists()) {
    return;
  } else {
    try {
      await directory.create(recursive: true).then((Directory directory) {
        commonPrint('目录 ${directory.path}被创建');
      });
    } catch (e) {
      showHint('文件夹创建失败，请检查文件保存地址是否设置', showType: 3);
      commonPrint('创建目录失败：$e');
    }
  }
}

Future<File> getFileByPath(String path) async {
  return File(path);
}

Future<Map<String, dynamic>> getFileContentByPath(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } else {
      commonPrint("文件不存在"); // 调试信息
    }
  } catch (e) {
    commonPrint('读取文件内容失败：$e');
  }
  return {};
}

Future<void> modifyFileContentByPath(Map<String, dynamic> newContent, String path, {bool needOriginalContent = true}) async {
  final file = await getFileByPath(path);
  Map<String, dynamic> existingContent = {};
  if (needOriginalContent) {
    existingContent = await getFileContentByPath(path);
  }
  existingContent.addAll(newContent);
  await file.writeAsString(jsonEncode(existingContent));
}

Future<List<String>> getAllFilePaths(String folderPath) async {
  Directory directory = Directory(folderPath);
  if (directory.existsSync()) {
    List<FileSystemEntity> entities = directory.listSync();
    List<String> filePaths = entities.whereType<File>().map((entity) => entity.path).toList();
    filePaths.sort((a, b) {
      RegExp digitRegExp = RegExp(r'\d+');
      int aValue = int.parse(digitRegExp.allMatches(a).last.group(0) ?? '');
      int bValue = int.parse(digitRegExp.allMatches(b).last.group(0) ?? '');
      return aValue.compareTo(bValue);
    });

    return filePaths;
  } else {
    return [];
  }
}

/// 检测字符串中是否含有中文
bool containsChinese(String text) {
  // 使用正则表达式匹配中文字符
  RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fa5]');
  return chineseRegExp.hasMatch(text);
}

List<String> getSubdirectories(String path) {
  List<String> subdirectories = [];

  Directory directory = Directory(path);
  if (directory.existsSync()) {
    List<FileSystemEntity> entities = directory.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is Directory) {
        String relativePath = entity.path.substring(path.length + 1);
        List<String> folders = relativePath.split(Platform.pathSeparator);
        if (folders.length >= 2) {
          String folderName = '${folders[0]}_${folders[1]}';
          subdirectories.add(folderName);
        }
      }
    }
  }

  return subdirectories;
}

Future<void> deleteFolder(String path) async {
  final directory = Directory(path);
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
    commonPrint('Folder deleted: $path');
  } else {
    commonPrint('Folder not found: $path');
  }
}

int countSubFolders(String path) {
  final directory = Directory(path);
  if (directory.existsSync()) {
    final subFolders = directory.listSync().whereType<Directory>();
    return subFolders.length;
  } else {
    return 0;
  }
}

String generateDraftId(bool isUpper) {
  const uuid = Uuid();
  final newUuid = uuid.v4();
  return isUpper ? newUuid.toUpperCase() : newUuid;
}

List<String> splitDrive(String path) {
  if (path.isNotEmpty && path[1] == ':') {
    return [path.substring(0, 2), path.substring(2)];
  } else {
    return ['', path];
  }
}

int getTimestamp() {
  DateTime now = DateTime.now();
  int microsecondTimestamp = now.microsecondsSinceEpoch;
  return microsecondTimestamp;
}

String getDeviceId() {
  String deviceId = '';
  try {
    deviceId = const Uuid().v1();
  } catch (e) {
    commonPrint('Error getting device id: $e');
  }
  return deviceId;
}

Future<String> getOSVersion() async {
  String osVersion = '';
  try {
    if (Platform.isWindows) {
      List<ProcessResult> resultList;
      resultList = await run('ver', verbose: false);
      if (resultList.isNotEmpty) {
        String fullResult = resultList[0].stdout.trim();
        int startIndex = fullResult.indexOf("版本 ") + 3;
        int endIndex = fullResult.indexOf("]", startIndex);
        if (startIndex >= 0 && endIndex > startIndex) {
          String version = fullResult.substring(startIndex, endIndex);
          osVersion = version;
          commonPrint('提取的版本号：$version');
        } else {
          commonPrint('未找到版本号');
        }
      }
    } else if (Platform.isLinux) {
      // 使用 package_info 包获取一些 Linux 系统信息，但可能不能完整提供版本信息
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      osVersion = 'Linux ${packageInfo.version}';
    } else if (Platform.isMacOS) {
      osVersion = 'MacOS ${Platform.operatingSystemVersion}';
    } else {
      commonPrint('不支持的操作系统');
    }
  } catch (e) {
    commonPrint('Error getting os version: $e');
  }
  return osVersion;
}

Future<String> getMacAddress() async {
  String macAddressFormatted = '';
  NetworkInfo networkInfo = NetworkInfo();

  try {
    final macAddress = await networkInfo.getWifiBSSID();
    if (macAddress != null) {
      macAddressFormatted = macAddress.toLowerCase().replaceAll(':', '');
    }
  } catch (e) {
    commonPrint('Error getting mac address: $e');
  }

  return macAddressFormatted;
}

String getOS() {
  String systemType = '';
  try {
    if (Platform.isMacOS) {
      systemType = 'MacOS';
    } else {
      systemType = Platform.operatingSystem;
    }
  } catch (e) {
    commonPrint('Error getting system type: $e');
  }
  return systemType.toLowerCase();
}

Future<String> getHardDiskId() async {
  String hardDiskId = '';
  try {
    String systemType = Platform.operatingSystem.toLowerCase();
    List<ProcessResult> resultList;
    if (systemType == 'windows') {
      resultList = await run('wmic diskdrive get SerialNumber', verbose: false);
      if (resultList.isNotEmpty) {
        hardDiskId = resultList[0].stdout.trim().split('\n')[1].trim();
      }
    } else if (systemType == 'linux') {
      resultList = await run('sudo hdparm -I /dev/sda | grep Serial', verbose: false);
      if (resultList.isNotEmpty) {
        hardDiskId = resultList[0].stdout.trim().split(' ').last;
      }
    } else if (systemType == 'macos') {
      resultList = await run("ioreg -r -c AppleAHCIDiskDriver -l | grep SerialNumber | awk '{print ${4}}'", verbose: false);
      if (resultList.isNotEmpty) {
        hardDiskId = resultList[0].stdout.trim().replaceAll('"', '');
      }
    } else {
      commonPrint('不支持的操作系统');
    }
  } catch (e) {
    commonPrint('Error getting hard_disk_id: $e');
  }
  return hardDiskId;
}

Map<String, dynamic> deepCopy(Map<String, dynamic> original) {
  Map<String, dynamic> copy = {};
  original.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      copy[key] = deepCopy(value);
    } else if (value is List) {
      copy[key] = List.from(value);
    } else {
      copy[key] = value;
    }
  });
  return copy;
}

class CancellationToken {
  bool isCancelled = false;
  bool isStarted = false;

  void cancel() {
    isCancelled = true;
    isStarted = true;
  }
}

Map<String, dynamic> parseStringToMap(String input) {
  Map<String, dynamic> map = {};

  List<String> keyValuePairs = input.split(', ');

  for (String pair in keyValuePairs) {
    List<String> keyValue = pair.split(': ');
    String key = keyValue[0].trim();
    String valueString = keyValue[1].trim();

    if (valueString.startsWith('"') && valueString.endsWith('"')) {
      // Remove surrounding quotes if value is a string
      valueString = valueString.substring(1, valueString.length - 1);
    }

    // Try to parse value as an integer or double
    dynamic value = int.tryParse(valueString) ?? double.tryParse(valueString) ?? valueString;

    map[key] = value;
  }

  return map;
}

///以下代码用于解析yaml格式返回值
class Category {
  String name;
  List<SubCategory> groups;

  Category(this.name, this.groups);
}

class SubCategory {
  String name;
  String color;
  List<Tag> tags;

  SubCategory(this.name, this.color, this.tags);
}

class Tag {
  String keyword;
  String translation;

  Tag(this.keyword, this.translation);
}

List<Category> parseYaml(String yamlString) {
  List<Category> categories = [];
  yamlString = yamlString.replaceAll(':d: 开心的笑_:D😀', ':d: 开心的笑_:D');
  var yamlList = loadYaml(yamlString);

  for (var item in yamlList) {
    String categoryName = item['name'];
    List<SubCategory> subCategories = [];

    for (var group in item['groups']) {
      String groupName = group['name'] ?? '';
      String groupColor = group['color'] ?? '';
      List<Tag> tags = [];
      if (group['tags'] is String) {
        // 如果tags是字符串，需要进一步解析
        List<String> tagStrings = group['tags'].split(':');
        for (String tagString in tagStrings) {
          List<String> tagParts = tagString.split(',');
          if (tagParts.length == 2) {
            tags.add(Tag(tagParts[0].trim(), tagParts[1].trim()));
          }
        }
      } else if (group['tags'] is List) {
        // 如果tags是列表，直接解析
        for (var tagData in group['tags']) {
          String? keyword = tagData.keys.first;
          String? translation = tagData.values.first;
          tags.add(Tag(keyword ?? '', translation ?? ''));
        }
      } else if (group['tags'] is Map) {
        group['tags'].forEach((key, value) {
          tags.add(Tag(key ?? '', value ?? ''));
        });
      }

      subCategories.add(SubCategory(groupName, groupColor, tags));
    }

    categories.add(Category(categoryName, subCategories));
  }

  return categories;
}

Future<List<String>> splitImage(String imageUrl) async {
  // 使用http库获取图片数据
  final response = await http.get(Uri.parse(imageUrl));
  // 将图片数据转换为Image对象
  img.Image image = img.decodeImage(response.bodyBytes)!;
  // 计算每份图片的大小
  int width = image.width ~/ 2;
  int height = image.height ~/ 2;

  // 创建一个列表来存储四份图片的base64编码
  List<String> base64Images = [];

  // 将图片分割为四份，并将每份图片转换为base64编码
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      // 使用copyCrop函数将图片分割为四份
      img.Image part = img.copyCrop(image, x: j * width, y: i * height, width: width, height: height); // 将每份图片转换为base64编码，并添加到列表中
      base64Images.add(base64Encode(img.encodePng(part)));
    }
  }

  // 返回四份图片的base64编码
  return base64Images;
}

Future<String> imageUrlToBase64(String imageUrl) async {
  // 发送网络请求以获取图像数据
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    // 将响应的字节数据转换为Uint8List
    final Uint8List imageData = response.bodyBytes;
    // 将Uint8List数据编码为base64字符串
    final String base64String = base64Encode(imageData);
    return base64String;
  } else {
    commonPrint('在线图片转换base64失败');
    return '';
  }
}

String getImageAspectRatio(String base64Image) {
  final Uint8List uint8List = base64.decode(base64Image);
  final image = img.decodeImage(uint8List);
  if (image != null) {
    final width = image.width;
    final height = image.height;
    final gcd = _calculateGCD(width, height);

    final aspectWidth = width ~/ gcd;
    final aspectHeight = height ~/ gcd;
    return '$aspectWidth:$aspectHeight';
  } else {
    return "Unknown";
  }
}

int _calculateGCD(int a, int b) {
  while (b != 0) {
    final int temp = a % b;
    a = b;
    b = temp;
  }
  return a;
}

void drawMosaicRect(Canvas canvas, Rect rect, double scale, {double mosaicBlockSize = 10.0}) {
  final mosaicPaint1 = Paint()
    ..color = Colors.black.withAlpha(102) // 黑色半透明
    ..style = PaintingStyle.fill;
  final mosaicPaint2 = Paint()
    ..color = Colors.white.withAlpha(102) // 白色半透明
    ..style = PaintingStyle.fill;

  for (double x = rect.left; x < rect.right; x += mosaicBlockSize * scale) {
    for (double y = rect.top; y < rect.bottom; y += mosaicBlockSize * scale) {
      final mosaicRect = Rect.fromPoints(
        Offset(x, y),
        Offset(x + mosaicBlockSize * scale, y + mosaicBlockSize * scale),
      );

      final mosaicPaint = (x ~/ (mosaicBlockSize * scale)).isEven
          ? ((y ~/ (mosaicBlockSize * scale)).isEven ? mosaicPaint1 : mosaicPaint2)
          : ((y ~/ (mosaicBlockSize * scale)).isEven ? mosaicPaint2 : mosaicPaint1);

      canvas.drawRect(mosaicRect, mosaicPaint);
    }
  }
}

void drawMosaicPath(Canvas canvas, Path path, double scale, {double mosaicBlockSize = 10.0}) {
  final mosaicPaint1 = Paint()
    ..color = Colors.black.withAlpha(102) // 黑色半透明
    ..style = PaintingStyle.fill;
  final mosaicPaint2 = Paint()
    ..color = Colors.white.withAlpha(102) // 白色半透明
    ..style = PaintingStyle.fill;

  // 填充路径
  for (double x = path.getBounds().left; x < path.getBounds().right; x += mosaicBlockSize * scale) {
    for (double y = path.getBounds().top; y < path.getBounds().bottom; y += mosaicBlockSize * scale) {
      final mosaicRect = Rect.fromPoints(
        Offset(x, y),
        Offset(x + mosaicBlockSize * scale, y + mosaicBlockSize * scale),
      );

      final mosaicPaint = (x ~/ (mosaicBlockSize * scale)).isEven
          ? ((y ~/ (mosaicBlockSize * scale)).isEven ? mosaicPaint1 : mosaicPaint2)
          : ((y ~/ (mosaicBlockSize * scale)).isEven ? mosaicPaint2 : mosaicPaint1);

      if (path.contains(Offset(x, y))) {
        canvas.drawRect(mosaicRect, mosaicPaint);
      }
    }
  }
}

bool isValidEmail(String email) {
  // 定义一个正则表达式模式来匹配电子邮件地址
  final RegExp emailRegExp = RegExp(
    r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$',
    caseSensitive: false,
    multiLine: false,
  );

  return emailRegExp.hasMatch(email);
}

Future<void> saveImageToDirectory(String base64Image, BuildContext context, {bool isShowHint = true, String imageUrl = ''}) async {
  Map<String, dynamic> settings = await Config.loadSettings();
  //这里判断图片的在线地址是否为空，不为空先转换base64
  if (imageUrl != '') {
    base64Image = await imageUrlToBase64(imageUrl);
  }
  DateTime currentDate = DateTime.now();
  DateTime now = DateTime.now();
  int timestamp = now.millisecondsSinceEpoch;
  String saveDirectory = settings['image_save_path'];
  saveDirectory =
      "$saveDirectory${Platform.pathSeparator}random_txt2img${Platform.pathSeparator}${currentDate.year}-${currentDate.month}-${currentDate.day}${Platform.pathSeparator}";
  Directory directory = Directory(saveDirectory);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  Uint8List bytes = base64Decode(base64Image);
  String fullPath = path.join(saveDirectory, '$timestamp.png');
  File file = File(fullPath);
  await file.writeAsBytes(bytes);
  if (context.mounted && isShowHint) {
    showHint('图片已保存在$saveDirectory$timestamp.png', showType: 2);
  }
}

Future<File> base64ToTempFile(String base64String) async {
  Uint8List bytes = base64.decode(base64String);
  DateTime now = DateTime.now();
  int timestamp = now.millisecondsSinceEpoch;
  final dcDirectory = await getApplicationDocumentsDirectory();
  String configPath = '${dcDirectory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}';
  String tempFilePath = '${configPath}tempImages${Platform.pathSeparator}';
  Directory directory = Directory(tempFilePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  String fullPath = path.join(tempFilePath, '$timestamp.png');
  File tempFile = File(fullPath);
  await tempFile.writeAsBytes(bytes);
  return tempFile;
}

Future<File> bytesToTempFile(Uint8List bytes) async {
  Map<String, dynamic> settings = await Config.loadSettings();
  DateTime now = DateTime.now();
  int timestamp = now.millisecondsSinceEpoch;
  String saveDirectory = settings['image_save_path'];
  String tempFilePath = '$saveDirectory${Platform.pathSeparator}tempImages${Platform.pathSeparator}';
  Directory directory = Directory(tempFilePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  String fullPath = path.join(tempFilePath, '$timestamp.png');
  File tempFile = File(fullPath);
  await tempFile.writeAsBytes(bytes);
  return tempFile;
}

class TYQWResponseData {
  final int id;
  final String event;
  final Map<String, dynamic> data;

  TYQWResponseData({
    required this.id,
    required this.event,
    required this.data,
  });

  factory TYQWResponseData.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>;
    return TYQWResponseData(
      id: json['id'] as int,
      event: json['event'] as String,
      data: dataJson,
    );
  }
}

bool isNumeric(String? str) {
  if (str == null) {
    return false;
  }
  return RegExp(r'^[0-9]+$').hasMatch(str);
}

Future<List<String>> getNonHiddenFileNames(String folderPath) async {
  List<String> fileNames = [];
  try {
    Directory directory = Directory(folderPath);
    if (await directory.exists()) {
      // 获取文件列表
      List<FileSystemEntity> entities = directory.listSync();

      // 过滤出非隐藏文件
      List<FileSystemEntity> nonHiddenEntities = entities.where((entity) {
        if (entity is File) {
          String fileName = basename(entity.path);
          // 判断文件是否以点开头
          return !fileName.startsWith('.');
        }
        return false;
      }).toList();

      List<String> filePaths = nonHiddenEntities.map((entity) => entity.path).toList();

      // 排序
      filePaths.sort((a, b) {
        RegExp digitRegExp = RegExp(r'\d+');
        var aMatches = digitRegExp.allMatches(a);
        var bMatches = digitRegExp.allMatches(b);

        if (aMatches.isEmpty && bMatches.isEmpty) {
          return a.compareTo(b);
        } else if (aMatches.isEmpty) {
          return -1;
        } else if (bMatches.isEmpty) {
          return 1;
        }

        int aValue = int.tryParse(aMatches.last.group(0) ?? '') ?? 0;
        int bValue = int.tryParse(bMatches.last.group(0) ?? '') ?? 0;
        return aValue.compareTo(bValue);
      });

      // 提取文件名
      for (var value in filePaths) {
        fileNames.add(basename(value));
      }
    } else {
      commonPrint("文件夹不存在");
    }
  } catch (e) {
    commonPrint("发生错误: $e");
  }
  return fileNames;
}

Future<String> uploadImageSup(String filePath, String imageUrl, File file) async {
  try {
    if (GlobalParams.isFreeVersion) {
      var myApi = MyApi();
      dio.FormData formData = dio.FormData.fromMap({
        "file": await dio.MultipartFile.fromFile(filePath),
      });
      dio.Response uploadResponse = await myApi.uploadImage(formData);
      if (uploadResponse.statusCode == 200) {
        if (uploadResponse.data is List) {
          imageUrl = uploadResponse.data[0]['src'];
        }
      } else {
        commonPrint('图片上传失败，原因是:${uploadResponse.statusMessage}');
      }
    } else {
      final supabase = Supabase.instance.client;
      var timeStr = currentDayStr();
      var uuid = const Uuid().v4();
      var fileName = "aiImage/$timeStr/$uuid.png";
      final String path = await supabase.storage.from('images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      commonPrint('图片上传后路径是 $path');
      final String signedUrl = await supabase.storage.from('images').createSignedUrl(fileName, 31622400);
      commonPrint('图片的签名路径是 $signedUrl ');
      imageUrl = signedUrl;
    }
    // 检查文件是否存在
    if (file.existsSync()) {
      file.deleteSync(); // 同步删除文件
    } else {
      commonPrint('图片上传后文件不存在，无法删除');
    }
  } catch (e) {
    commonPrint(e);
  }
  return imageUrl;
}

Future<String> uploadFileToALiOss(String filePath, String imageUrl, File file,
    {String fileType = 'png', bool needDelete = true, File? videoFile, String? setFileName}) async {
  var myApi = MyApi();
  if (GlobalParams.isFreeVersion) {
    dio.FormData formData = dio.FormData.fromMap({
      "file": await dio.MultipartFile.fromFile(filePath),
    });
    dio.Response uploadResponse = await myApi.uploadImage(formData);
    if (uploadResponse.statusCode == 200) {
      if (uploadResponse.data is List) {
        imageUrl = uploadResponse.data[0]['src'];
      }
    } else {
      commonPrint('文件上传失败，原因是:${uploadResponse.statusMessage}');
    }
  } else {
    final settings = await Config.loadSettings();
    String bucketName = settings['oss_bucket_name'] ?? ''; //wqjimages
    String ossEndpoint = settings['oss_endpoint'] ?? '';
    String ossApiUrl = settings['oss_api_url'] ?? ''; //https://oss.zxai.fun/oss_token
    dio.Response response = await dio.Dio().get(ossApiUrl);
    if (response.statusCode == 200) {
      var jsonData = jsonDecode("$response");
      alioss.Auth authGetter() {
        return alioss.Auth(
          accessKey: jsonData['AccessKeyId'],
          accessSecret: jsonData['AccessKeySecret'],
          expire: jsonData['Expiration'],
          secureToken: jsonData['SecurityToken'],
        );
      }

      alioss.Client.init(authGetter: authGetter, ossEndpoint: ossEndpoint, bucketName: bucketName, dio: Dio());
    }
    var timeStr = currentDayStr();
    var uuid = const Uuid().v4();
    if (setFileName != null) {
      uuid = setFileName;
    }
    var fileName = "aiFile/$timeStr/$uuid.$fileType";
    final resp = await alioss.Client().putObjectFile(
      filePath,
      fileKey: fileName,
      option: const alioss.PutRequestOption(aclModel: alioss.AclMode.publicWrite),
    );
    if (resp.statusCode == 200) {
      imageUrl = fileName;
    } else {
      commonPrint('阿里云上传失败');
    }
  }
  // 检查文件是否存在，确定是否需要删除
  if (needDelete) {
    if (file.existsSync()) {
      try {
        file.deleteSync(); // 同步删除文件
      } catch (e) {
        commonPrint('文件上传后删除文件时出错：$e');
      }
    }
    if (videoFile != null && videoFile.existsSync()) {
      try {
        videoFile.deleteSync();
      } catch (e) {
        commonPrint('视频文件上传后删除文件时出错：$e');
      }
    }
  }
  return imageUrl;
}

Future<ui.Image> getImageFromBase64(String base64String) async {
  Uint8List imageBytes = base64Decode(base64String);
  final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

int closestMultipleOf64(int number) {
  return (number / 64).floor() * 64;
}

Map<String, int> processDimensions(int width, int height) {
  // 四舍五入到最接近的64的倍数
  int processedWidth = closestMultipleOf64(width);
  int processedHeight = closestMultipleOf64(height);

  // 确保宽度和高度不超过2048
  if (processedWidth > 2048 || processedHeight > 2048) {
    if (processedWidth > processedHeight) {
      // 缩放高度以保持宽高比
      double aspectRatio = height / width;
      processedWidth = 2048;
      processedHeight = closestMultipleOf64((2048 * aspectRatio).toInt());
    } else {
      // 缩放宽度以保持宽高比
      double aspectRatio = width / height;
      processedHeight = 2048;
      processedWidth = closestMultipleOf64((2048 * aspectRatio).toInt());
    }
  }

  return {'width': processedWidth, 'height': processedHeight};
}

Future<String> screenResolutionChecker() async {
  if (Platform.isMacOS || Platform.isWindows) {
    // 定义不同分辨率的像素范围
    const fullHdPixels = 1920 * 1080; // 1080p
    const twoKPixels = 2560 * 1440; // 2K
    const fourKPixels = 3840 * 2160; // 4K
    var screenSize = await NativeScreenUtils.getSystemScreenResolution();
    if (screenSize.contains('x')) {
      var width = int.parse(screenSize.split('x')[0]);
      var height = int.parse(screenSize.split('x')[1]);
      var totalPixels = width * height;
      if (totalPixels >= fourKPixels) {
        return '4K';
      } else if (totalPixels >= twoKPixels) {
        return '2K';
      } else if (totalPixels >= fullHdPixels) {
        return '1080p';
      } else {
        return 'Below 1080p';
      }
    } else {
      return 'Error on getting screen size';
    }
  } else {
    return '';
  }
}

String checkInput(String kbTitle, String fullStr, String appKey, String salt, int timestamp, String appSec) {
  if (kbTitle.length <= 20) {
    fullStr = '$appKey$kbTitle$salt$timestamp$appSec';
  } else {
    String first10Str = kbTitle.substring(0, 10);
    String last10Str = kbTitle.substring(kbTitle.length - 10, kbTitle.length);
    String input = '$first10Str${kbTitle.length}$last10Str';
    fullStr = '$appKey$input$salt$timestamp$appSec';
  }
  return fullStr;
}

String generateSha256Hash(String input) {
  var bytes = utf8.encode(input); // data being hashed
  var digest = sha256.convert(bytes);
  return digest.toString();
}

// 格式化文件大小为KB或MB
String formatFileSize(int bytes) {
  const int KB = 1024;
  const int MB = KB * 1024;

  if (bytes >= MB) {
    double mbSize = bytes / MB;
    return '${mbSize.toStringAsFixed(2)} MB';
  } else {
    double kbSize = bytes / KB;
    return '${kbSize.toStringAsFixed(2)} KB';
  }
}

String generateRandomString(int length) {
  const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join('');
}

//获取当前时间戳
String getCurrentTimestamp({String format = ''}) {
  DateTime now = DateTime.now();

  if (format.isNotEmpty) {
    DateFormat formatter = DateFormat(format);
    return formatter.format(now);
  } else {
    return now.millisecondsSinceEpoch.toString();
  }
}

int generate15DigitNumber() {
  Random random = Random();
  // 分两段生成随机数
  int part1 = random.nextInt(1000000); // 0-999999
  int part2 = random.nextInt(1000000); // 0-999999
  // 拼接并确保结果为正数
  return (part1 * 1000000 + part2).abs();
}

String getFileExtension(String filePath) {
  List<String> parts = filePath.split('.');

  String extension;
  if (parts.length > 1) {
    extension = parts.last;
  } else {
    extension = '';
  }
  return extension;
}

int compareVersions(String oldVersion, String newVersion) {
  List<String> v1Parts = oldVersion.split('.');
  List<String> v2Parts = newVersion.split('.');

  for (int i = 0; i < v1Parts.length; i++) {
    int v1Part = int.parse(v1Parts[i]);
    int v2Part = int.parse(v2Parts[i]);

    if (v1Part > v2Part) {
      return -1;
    } else if (v1Part < v2Part) {
      return 1;
    }
  }
  return 0;
}

Map<String, String> modelMap = {for (var model in GlobalParams.aiModels) model['model_name']: model['model_id']};

// 查找函数：根据 model_name 查找对应的 model_id
String findModelIdByName(String modelName) {
  return modelMap[modelName] ?? modelName;
}

String findModelDescByName(String modelName) {
  for (var model in GlobalParams.aiModels) {
    if (model['model_name'] == modelName) {
      return model['describe'].replaceAll('\\n', '\n');
    }
  }
  return '';
}

int isSeniorModel(String modelName) {
  for (var model in GlobalParams.aiModels) {
    if (model['model_name'] == modelName) {
      return model['is_senior'];
    }
  }
  return 0;
}

int modelMagnification(String modelName) {
  for (var model in GlobalParams.aiModels) {
    if (model['model_name'] == modelName) {
      return model['magnification'];
    }
  }
  return 1;
}

bool isSupportChatStream(String modelName) {
  for (var model in GlobalParams.aiModels) {
    if (model['model_name'] == modelName) {
      return model['support_stream'];
    }
  }
  return false;
}

bool isSupportChatContext(String modelName) {
  for (var model in GlobalParams.aiModels) {
    if (model['model_name'] == modelName) {
      return model['is_support_context'];
    }
  }
  return true;
}

IconData getFileIcon(String extension) {
  switch (extension) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'ppt':
    case 'pptx':
      return Icons.filter_frames_sharp;
    case 'txt':
      return Icons.text_snippet;
    case 'mp3':
    case 'wav':
      return Icons.audio_file;
    default:
      return Icons.file_present_rounded;
  }
}

String truncateString(String input, int maxLength) {
  if (input.length <= maxLength) {
    return input;
  }

  List<String> parts = input.split('.');
  if (parts.length >= 2) {
    String start = parts.first;
    String end = parts.last;
    int availableLength = maxLength - end.length - 3;

    if (availableLength > 0) {
      start = start.substring(0, availableLength);
    } else {
      // 如果空间不足以容纳 start 和 end，直接截断输入字符串
      return '${input.substring(0, maxLength)}...';
    }

    return '$start...$end';
  }

  return '${input.substring(0, maxLength)}...';
}

Map<String, dynamic> fillMissingAttributes(Map<String, dynamic> source, Map<String, dynamic> target) {
  // 遍历 source 的每一个 key-value
  source.forEach((key, value) {
    // 如果 target 中不存在该 key
    if (!target.containsKey(key)) {
      // 将 source 中的 key-value 添加到 target 中
      target[key] = value;
    }
  });
  return target;
}

Map<String, dynamic> fillEmptyAttributes(Map<String, dynamic> source, Map<String, dynamic> target) {
  // 遍历 source 的每一个 key-value
  source.forEach((key, value) {
    // 如果 target 中存在该 key
    if (target.containsKey(key)) {
      // 将 source 中的 value 添加到 target 中
      if (value is String && target[key] is String && value.isNotEmpty && target[key].isEmpty) {
        target[key] = value;
      }
    }
  });
  return target;
}

String removeExtraSpaces(String input) {
  // 使用正则表达式替换多个连续的空格，但保留换行符（\n）
  String result = input.replaceAll(RegExp(r'[^\S\r\n]+'), ' ').trim();
  return result;
}

bool isImageFile(String fileName) {
  final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', 'webp'];
  return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
}

Future<void> myLaunchUrl(Uri url) async {
  dismissHint();
  if (url.toString().startsWith('page')) {
    //这里是为了适配跳转页面的逻辑
    if (!GlobalParams.isFreeVersion) {
      final box = GetStorage();
      await box.write('gotoPage', GlobalParams.isAdminVersion ? 11 : 9);
    }
  } else if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}

Future<bool> checkUser() async {
  bool canUse = false;
  Map<String, dynamic> settings = await Config.loadSettings();
  String userId = settings['user_id'] ?? '';
  final user = await SupabaseHelper().query('my_users', {'user_id': userId});
  if (user.isNotEmpty) {
    canUse = user[0]['is_delete'];
  }
  return !canUse;
}

final avatarMap = {
  'gpt-3': 'assets/images/gpt-3.png',
  'gpt-4': 'assets/images/gpt-4.png',
  'o1': 'assets/images/gpt-4.png',
  'o3': 'assets/images/gpt-4.png',
  'claude': 'assets/images/claude.png',
  '微软': 'assets/images/copilot.png',
  '豆包': 'assets/images/doubao.png',
  'MJ绘画': 'assets/images/midjourney.png',
  'Mini': 'assets/images/minimax.png',
  '月': 'assets/images/moonshot.png',
  '零一': 'assets/images/01ww.png',
  'AI音乐': 'assets/images/sunoai.png',
  '通义千问': 'assets/images/tyqw.png',
  '讯飞': 'assets/images/xfxh.png',
  'grok': 'assets/images/grok.png',
  'Gemi': 'assets/images/gemini.png',
  '带思考': 'assets/images/gemini.png',
  '智谱': 'assets/images/zpai.png',
  'deepseek': 'assets/images/deepseek.png',
  'DeepSeek': 'assets/images/deepseek.png',
};

// Helper function to get the appropriate image path based on the model
String getAvatarImage(String model, bool isSentByMe) {
  if (isSentByMe) {
    return 'assets/images/chat_user_default_avatar.png';
  }

  // Find the first matching model prefix in the map
  return avatarMap.entries
      .firstWhere(
        (entry) => model.startsWith(entry.key),
        orElse: () => const MapEntry('', 'assets/images/app_icon.png'),
      )
      .value;
}

// 构建二维码内容
Widget buildQRCodeContent(String qrcode, String payMethod) {
  return Padding(
    padding: const EdgeInsets.only(top: 6, left: 30, right: 30),
    child: payMethod == 'alipay' ? buildAlipayQRCode(qrcode) : buildWechatQRCode(qrcode),
  );
}

// 构建支付宝二维码
Widget buildAlipayQRCode(String codeUrl) {
  return ExtendedImage.network(
    codeUrl,
    fit: BoxFit.contain,
  );
}

// 构建微信二维码
Widget buildWechatQRCode(String qrcode) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(128),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: PrettyQrView.data(
      data: qrcode,
      decoration: const PrettyQrDecoration(
        shape: PrettyQrSmoothSymbol(roundFactor: 0.95),
        image: PrettyQrDecorationImage(
          image: AssetImage('assets/images/img_icon.png'),
        ),
      ),
    ),
  );
}

Future<void> insertOrder(Map<String, dynamic> payParams, String? tradeNo) async {
  if (payParams.containsKey('notify_url')) {
    payParams.remove('notify_url');
  }
  if (payParams.containsKey('return_url')) {
    payParams.remove('return_url');
  }
  if (payParams.containsKey('clientip')) {
    payParams.remove('clientip');
  }
  Map<String, dynamic> settings = await Config.loadSettings();
  String userId = settings['user_id'] ?? '';
  payParams['user_id'] = userId;
  payParams['trade_no'] = tradeNo;
  payParams['trade_status'] = 'TRADE_PENDING';
  await SupabaseHelper().insert('orders', payParams);
}

Future<void> checkOrderInfo(String? tradeNo, int packageId, BuildContext context) async {
  Map<String, dynamic> settings = await Config.loadSettings();
  String userId = settings['user_id'] ?? '';
  Map<String, dynamic> paidInfo = {};
  paidInfo['order_no'] = tradeNo;
  paidInfo['type'] = 1;
  try {
    var orderInfo = await SupabaseHelper().query('orders', {'trade_no': tradeNo!});
    if (EasyLoading.isShow) {
      EasyLoading.dismiss();
    }
    if (orderInfo.isNotEmpty) {
      var order = orderInfo[0];
      String orderStatus = order['trade_status'];
      if (orderStatus == 'TRADE_SUCCESS') {
        if (context.mounted) {
          showHint('感谢购买', showType: 2);
          Navigator.of(context).pop();
        }
        var response = await SupabaseHelper().runRPC('purchase_package', {'p_package_template_id': packageId, 'p_user_id': userId});
        commonPrint(response);
        await checkUserQuota(userId); //查询用户的套餐
      } else {
        showHint('查询到订单未成功支付，请重新购买', showType: 3);
      }
    } else {
      showHint('未查询到订单，请重新购买', showType: 3);
    }
    return;
  } catch (e) {
    commonPrint(e);
  } finally {
    if (EasyLoading.isShow) {
      EasyLoading.dismiss();
    }
  }
}

bool getRealDarkMode(ChangeSettings settings) {
  return ((settings.isAutoMode && settings.isSystemDarkMode) || (!settings.isAutoMode && settings.isDarkMode));
}

Future<String?> getCurrentSessionId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('sessionId');
}

Future<void> saveSessionId(String sessionId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sessionId', sessionId);
}

Future<Map<String, dynamic>> getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isWindows) {
    final info = await deviceInfo.windowsInfo;
    return {
      'os': 'Windows',
      'version': info.majorVersion,
      'deviceId': info.deviceId,
      'computerName': info.computerName,
    };
  } else if (Platform.isMacOS) {
    final info = await deviceInfo.macOsInfo;
    return {
      'os': 'macOS',
      'version': info.majorVersion,
      'model': info.model,
      'computerName': info.computerName,
    };
  } else if (Platform.isLinux) {
    final info = await deviceInfo.linuxInfo;
    return {
      'os': 'Linux',
      'name': info.name,
      'version': info.version,
      'id': info.id,
    };
  } else if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return {
      'os': 'Android',
      'name': info.model,
      'version': info.board,
      'id': info.id,
    };
  } else if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    return {
      'os': 'iOS',
      'name': info.name,
      'version': info.systemVersion,
      'id': info.identifierForVendor,
    };
  }
  throw UnsupportedError('Unsupported platform');
}

Future<Map<String,dynamic>> checkUserQuota(String userId) async {
  Map<String,dynamic> userQuotas = {};
  final box = GetStorage();
  if (!GlobalParams.isFreeVersion) {
    //查询用户套餐数据
    final response = await SupabaseHelper().runRPC('get_user_available_quota', {'p_user_id': userId});
    if (response['code'] == 200) {
      var commonChatNum = response['data']['total_available']['basic_chat'] == -1 ? 1000000000 : response['data']['total_available']['basic_chat'];
      var seniorChatNum = response['data']['total_available']['premium_chat'];
      var commonDrawNum = response['data']['total_available']['slow_drawing'];
      var seniorDrawNum = response['data']['total_available']['fast_drawing'];
      var tokens = response['data']['total_available']['token'];
      var videosNum = response['data']['total_available']['ai_video'];
      var musicsNum = response['data']['total_available']['ai_music'];
      userQuotas = response['data']['total_available'];
      await box.write('commonChatNum', commonChatNum);
      await box.write('seniorChatNum', seniorChatNum);
      await box.write('commonDrawNum', commonDrawNum);
      await box.write('seniorDrawNum', seniorDrawNum);
      await box.write('tokens', tokens);
      await box.write('musicsNum', musicsNum);
      await box.write('videosNum', videosNum);
    } else {
      await box.write('commonChatNum', 0);
      await box.write('seniorChatNum', 0);
      await box.write('commonDrawNum', 0);
      await box.write('seniorDrawNum', 0);
      await box.write('tokens', 0);
      await box.write('musicsNum', 0);
      await box.write('videosNum', 0);
    }
  }
  return userQuotas;
}

StreamTransformer<T, T> singleSubscription<T>() {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;

  controller = StreamController<T>(
    onListen: () {
      subscription = controller.stream.listen(null);
    },
    onCancel: () {
      subscription?.cancel();
      subscription = null;
    },
  );

  return StreamTransformer<T, T>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data);
    },
  );
}

Future<Map<String, dynamic>> cuGetImages(Map<String, dynamic> prompt, {bool isReImagine = true}) async {
  final myApi = MyApi();
  Map<String, dynamic> savedSettings = await Config.loadSettings();
  String clientId = '';
  String? getClientId = savedSettings['client_id'];
  if (getClientId == null) {
    final String newClientId = const Uuid().v4();
    Map<String, dynamic> saveSettings = {'client_id': newClientId};
    clientId = newClientId;
    await Config.saveSettings(saveSettings);
  } else {
    clientId = getClientId;
  }
  String? serverAddress = savedSettings['cu_url'];
  final Map<String, dynamic> outputImages = {};
  if (serverAddress == null || serverAddress == '') {
    showHint('请先在设置页面配置comfyui的地址');
  } else {
    serverAddress = serverAddress.replaceAll('http://', '');
    final WebSocketChannel channel = IOWebSocketChannel.connect("ws://$serverAddress/ws?clientId=$clientId");
    try {
      dio.Response queueResponse = await myApi.cuQueuePrompt(prompt);
      if (queueResponse.statusCode == 200) {
        final String promptId = queueResponse.data['prompt_id'];
        final streamController = StreamController<dynamic>.broadcast();
        final broadcastStream = channel.stream.transform(singleSubscription());
        broadcastStream.listen((dynamic out) async {
          if (out is String) {
            final Map<String, dynamic> message = jsonDecode(out);
            if (message['type'] == 'executing') {
              final Map<String, dynamic> data = message['data'];
              if (data['node'] == null && data['prompt_id'] == promptId) {
                streamController.add(null); // 执行完成
              }
            }
          }
        });
        await streamController.stream.first; // 等待执行完成
        dio.Response history = await myApi.cuGetHistory(promptId);
        if (history.statusCode == 200) {
          final Map<String, dynamic> outputs = history.data[promptId]['outputs'];
          for (String nodeId in outputs.keys) {
            final Map<String, dynamic> nodeOutput = outputs[nodeId];
            if (isReImagine) {
              if (nodeOutput.containsKey('images')) {
                final List<Uint8List> imagesOutput = [];
                for (dynamic image in nodeOutput['images']) {
                  dio.Response imageBytes = await myApi.cuGetImage(image['filename'], image['subfolder'], image['type']);
                  if (imageBytes.statusCode == 200) {
                    imagesOutput.add(imageBytes.data);
                  }
                }
                outputImages[nodeId] = imagesOutput;
              }
            } else {
              if (nodeOutput.containsKey('text')) {
                outputImages[nodeId] = nodeOutput['text'][0];
              }
            }
          }
        }
      }
    } finally {
      channel.sink.close();
    }
  }
  return outputImages;
}

Future<List<String>> getTaggerInterrogators() async {
  final myApi = MyApi();
  List<String> interrogators = [];
  Map<String, dynamic> settings = await Config.loadSettings();
  String sdUrl = settings['sdUrl'] ?? '';
  try {
    dio.Response response = await myApi.getTaggerInterrogators(sdUrl);
    if (response.statusCode == 200) {
      List<dynamic> getInterrogators = List<String>.from(response.data['models']);
      for (String interrogator in getInterrogators) {
        if (!interrogators.contains(interrogator)) {
          interrogators.add(interrogator);
        }
      }
    } else {
      showHint('获取反推模型失败，请检查sd配置。异常是${response.statusMessage}');
    }
  } catch (e) {
    showHint('获取反推模型失败，请检查sd配置。异常是$e');
  }
  return interrogators;
}

TextStyle getDefaultTextStyle(double fontSize) {
  if (Platform.isWindows) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'MyFont',
      // Windows 平台特定的渲染参数
      height: 1.2, // 调整行高
      letterSpacing: -0.3, // 稍微收紧字间距
    );
  } else if (Platform.isMacOS || Platform.isIOS) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: const ['PingFang SC', 'Heiti SC'],
      height: 1.3,
    );
  } else {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans SC'],
      height: 1.2,
    );
  }
}

final globalTextTheme = TextTheme(
  // 为不同文字样式分别设置
  displayLarge: getDefaultTextStyle(30),
  displayMedium: getDefaultTextStyle(24),
  displaySmall: getDefaultTextStyle(20),
  headlineMedium: getDefaultTextStyle(18),
  headlineSmall: getDefaultTextStyle(16),
  titleLarge: getDefaultTextStyle(16),
  titleMedium: getDefaultTextStyle(14),
  titleSmall: getDefaultTextStyle(14),
  bodyLarge: getDefaultTextStyle(14),
  bodyMedium: getDefaultTextStyle(14),
  bodySmall: getDefaultTextStyle(12),
  labelLarge: getDefaultTextStyle(14),
  labelMedium: getDefaultTextStyle(12),
  labelSmall: getDefaultTextStyle(10),
);
