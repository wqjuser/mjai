import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionUtils {
  /// 生成32位密钥
  static Key _generateKey(String key) {
    var bytes = utf8.encode(key);
    var digest = sha256.convert(bytes);
    return Key.fromBase64(base64Encode(digest.bytes));
  }

  /// 从密钥生成固定的IV
  static IV _generateFixedIV(String key) {
    var bytes = utf8.encode(key);
    var digest = sha256.convert(bytes);
    // 使用密钥的前16个字节作为IV
    return IV.fromBase64(base64Encode(digest.bytes.sublist(0, 16)));
  }

  /// 加密方法 - 相同输入将产生相同输出
  static String encrypt(String content, String key) {
    try {
      final encryptKey = _generateKey(key);
      final iv = _generateFixedIV(key);

      final encrypter = Encrypter(AES(encryptKey, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(content, iv: iv);

      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 解密方法
  static String decrypt(String encryptedContent, String key) {
    try {
      final decryptKey = _generateKey(key);
      final iv = _generateFixedIV(key);

      final decrypter = Encrypter(AES(decryptKey, mode: AESMode.cbc));
      final decrypted = decrypter.decrypt64(encryptedContent, iv: iv);

      return decrypted;
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }
}
