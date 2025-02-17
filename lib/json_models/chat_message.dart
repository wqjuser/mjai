import 'package:tuitu/json_models/uploading_file.dart';
import 'dart:async';

import '../utils/encryption_utils.dart';

class ChatMessage {
  String text;
  bool isSentByMe;
  String model;
  String? sendTime;
  String userName;
  List<UploadingFile>? files;
  Timer? animationTimer;
  String? fullText;
  bool? isPrivate;
  String? encryptKey;
  bool? isEncrypted;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.model,
    this.sendTime,
    this.files,
    this.userName = '',
    this.fullText,
    this.isPrivate = false,
    this.encryptKey = '',
    this.isEncrypted = false,
  });

  Map<String, dynamic> toJson() => {
        'text': (isPrivate != null && isPrivate! && encryptKey != null && encryptKey!.isNotEmpty)
            ? EncryptionUtils.encrypt(text, encryptKey!)
            : text,
        'isSentByMe': isSentByMe,
        'model': model,
        'sendTime': sendTime,
        'userName': userName,
        'files': files?.map((file) => file.toJson()).toList(),
        'fullText': (isPrivate != null && isPrivate! && encryptKey != null && encryptKey!.isNotEmpty && fullText != null)
            ? EncryptionUtils.encrypt(fullText!, encryptKey!)
            : fullText,
        'isPrivate': isPrivate,
        'encryptKey': encryptKey,
        'isEncrypted': true
      };

  Map<String, dynamic> toShareJson() => {
        'role': userName == '魔镜AI'
            ? 'system'
            : isSentByMe
                ? 'user'
                : 'assistant',
        'content': (fullText != null && fullText!.isNotEmpty) ? fullText : text
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    bool isPrivate = json['isPrivate'] ?? false;
    String encryptKey = json['encryptKey'] ?? '';
    bool isEncrypted = json['isEncrypted'] ?? false;
    return ChatMessage(
      text: (isPrivate && encryptKey.isNotEmpty && isEncrypted && json['text'] != null && json['text'].isNotEmpty)
          ? EncryptionUtils.decrypt(json['text'], encryptKey)
          : json['text'],
      isSentByMe: json['isSentByMe'],
      model: json['model'],
      sendTime: json['sendTime'],
      userName: json['userName'] ?? '',
      files: json['files'] != null ? List<UploadingFile>.from(json['files'].map((x) => UploadingFile.fromJson(x))) : null,
      fullText: (isPrivate && encryptKey.isNotEmpty && isEncrypted && json['fullText'] != null && json['fullText'].isNotEmpty)
          ? EncryptionUtils.decrypt(json['fullText'], encryptKey)
          : json['fullText'],
      isPrivate: json['isPrivate'] ?? false,
      encryptKey: json['encryptKey'],
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }

  void dispose() {
    animationTimer?.cancel();
  }
}
