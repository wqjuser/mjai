import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../utils/encryption_utils.dart';

class UploadingFile {
  final PlatformFile file;
  final String key;
  bool isUploaded = false;
  bool uploadFailed = false;
  String? content;
  String fileUrl;
  bool isHovered = false;
  CancelToken? cancelToken;
  bool? isPrivate;
  String? encryptKey;
  bool? isEncrypted;

  UploadingFile({
    required this.key,
    required this.file,
    this.isUploaded = false,
    this.uploadFailed = false,
    this.content = '',
    this.fileUrl = '',
    this.cancelToken,
    this.isHovered = false,
    this.isPrivate = false,
    this.encryptKey = '',
    this.isEncrypted = false,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'fileName': file.name,
        'filePath': file.path,
        'isUploaded': isUploaded,
        'uploadFailed': uploadFailed,
        'content': (isPrivate != null &&
                isPrivate! &&
                encryptKey != null &&
                encryptKey!.isNotEmpty &&
                content != null &&
                content!.isNotEmpty)
            ? EncryptionUtils.encrypt(content!, encryptKey!)
            : content,
        'fileUrl': (isPrivate != null && isPrivate! && encryptKey != null && encryptKey!.isNotEmpty && fileUrl.isNotEmpty)
            ? EncryptionUtils.encrypt(fileUrl, encryptKey!)
            : fileUrl,
        'isHovered': isHovered,
        'isPrivate': isPrivate,
        'encryptKey': encryptKey,
        'isEncrypted': true,
        // 'cancelToken': cancelToken, // CancelToken 不能直接序列化，需要单独处理
      };

  factory UploadingFile.fromJson(Map<String, dynamic> json) {
    bool isPrivate = json['isPrivate'] ?? false;
    String encryptKey = json['encryptKey'] ?? '';
    bool isEncrypted = json['isEncrypted'] ?? false;
    return UploadingFile(
      key: json['key'] ?? '',
      // 加入默认值防止 null 错误
      file: PlatformFile(
        name: json['fileName'] ?? '', // 加入默认值防止 null 错误
        path: json['filePath'],
        size: 0, // 这里可以用更合适的方式设置文件大小
      ),
      isUploaded: json['isUploaded'] ?? false,
      // 加入默认值
      uploadFailed: json['uploadFailed'] ?? false,
      // 加入默认值
      content: (isPrivate && encryptKey.isNotEmpty && isEncrypted && json['content'] != null && json['content'].isNotEmpty)
          ? EncryptionUtils.decrypt(json['content'], encryptKey)
          : json['content'] ?? '',
      fileUrl: (isPrivate && encryptKey.isNotEmpty && isEncrypted && json['fileUrl'] != null && json['fileUrl'].isNotEmpty)
          ? EncryptionUtils.decrypt(json['fileUrl'], encryptKey)
          : json['fileUrl'] ?? '',
      cancelToken: null,
      // CancelToken 不能直接反序列化
      isHovered: json['isHovered'] ?? false,
      // 加入默认值
      isPrivate: json['isPrivate'] ?? false,
      encryptKey: json['encryptKey'] ?? '',
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }
}
