import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  // 使用固定的盐值
  static const String _fixedSalt = "wqj_user_salt_value";
  static const int _iterations = 1000;  // 迭代次数，可以根据需要调整

  /// 对密码进行加密
  static String hashPassword(String password) {
    // 组合密码和盐值
    final bytes = utf8.encode(password + _fixedSalt);
    List<int> digest = bytes;

    // 多次迭代以增加安全性
    for (var i = 0; i < _iterations; i++) {
      digest = sha256.convert(digest).bytes;
    }

    // 返回base64编码的结果
    return base64.encode(digest);
  }

  /// 验证密码
  static bool verifyPassword(String password, String hashedPassword) {
    // 使用相同的方式加密输入的密码
    String hashedInput = hashPassword(password);
    // 比较两个哈希值
    return hashedInput == hashedPassword;
  }
}