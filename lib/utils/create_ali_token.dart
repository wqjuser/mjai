import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const String TIME_ZONE = "GMT";
const String FORMAT_ISO8601 = "yyyy-MM-dd'T'HH:mm:ss'Z'";
const String URL_ENCODING = "UTF-8";
const String ALGORITHM_NAME = "HmacSHA1";
const String ENCODING = "UTF-8";

String? token;
int expireTime = 0;

/// 获取当前时间戳，使用ISO8601格式，带有UTC时区。
String getISO8601Time() {
  var nowDate = DateTime.now().toUtc();
  var df = DateFormat(FORMAT_ISO8601);
  return df.format(nowDate);
}

/// 生成唯一的UUID。
String getUniqueNonce() {
  var uuid = const Uuid();
  return uuid.v4();
}

/// 使用UTF-8字符集按照RFC3986规则进行URL编码。
String percentEncode(String value) {
  return Uri.encodeComponent(value).replaceAll("+", "%20").replaceAll("*", "%2A").replaceAll("%7E", "~");
}

/// 对查询参数进行规范化处理，并创建请求字符串。
String canonicalizedQuery(Map<String, String> queryParamsMap) {
  var sortedKeys = queryParamsMap.keys.toList()..sort();
  var canonicalizedQueryString = StringBuffer();
  for (var key in sortedKeys) {
    canonicalizedQueryString
      ..write("&")
      ..write(percentEncode(key))
      ..write("=")
      ..write(percentEncode(queryParamsMap[key]!));
  }
  var queryString = canonicalizedQueryString.toString().substring(1);
  if (kDebugMode) {
    print("规范化后的请求参数串: $queryString");
  }
  return queryString;
}

/// 创建签名字符串以用于生成签名。
String createStringToSign(String method, String urlPath, String queryString) {
  var strBuilderSign = StringBuffer();
  strBuilderSign
    ..write(method)
    ..write("&")
    ..write(percentEncode(urlPath))
    ..write("&")
    ..write(percentEncode(queryString));
  var stringToSign = strBuilderSign.toString();
  if (kDebugMode) {
    print("构造的签名字符串: $stringToSign");
  }
  return stringToSign;
}

/// 计算签名。
String sign(String stringToSign, String accessKeySecret) {
  var hmac = Hmac(sha1, utf8.encode(accessKeySecret));
  var signData = hmac.convert(utf8.encode(stringToSign));
  var signBase64 = base64Encode(signData.bytes);
  if (kDebugMode) {
    print("计算得到的签名: $signBase64");
  }
  var signUrlEncode = percentEncode(signBase64);
  if (kDebugMode) {
    print("UrlEncode编码后的签名: $signUrlEncode");
  }
  return signUrlEncode;
}

/// 发送HTTP GET请求以获取token和有效期时间戳。
void processGETRequest(String queryString) async {
  var url = Uri.parse("http://nls-meta.cn-shanghai.aliyuncs.com");
  url = url.replace(query: queryString);
  if (kDebugMode) {
    print("HTTP请求链接: $url");
  }

  try {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var result = response.body;
      var rootObj = jsonDecode(result);
      var tokenObj = rootObj["Token"];
      if (tokenObj != null) {
        token = tokenObj["Id"];
        expireTime = tokenObj["ExpireTime"];
      } else {
        if (kDebugMode) {
          print("提交获取Token请求失败: $result");
        }
      }
    } else {
      if (kDebugMode) {
        print("提交获取Token请求失败: ${response.body}");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("发送HTTP请求时出错: $e");
    }
  }
}

String getAliToken(List<String> args) {
  String aliToken = '';
  if (args.length < 2) {
    if (kDebugMode) {
      print("CreateToken需要参数： <AccessKey Id> <AccessKey Secret>");
    }
    return aliToken;
  }
  var accessKeyId = args[0];
  var accessKeySecret = args[1];
  if (kDebugMode) {
    print(getISO8601Time());
  }

  // 所有请求参数
  var queryParamsMap = {
    "AccessKeyId": accessKeyId,
    "Action": "CreateToken",
    "Version": "2019-02-28",
    "Timestamp": getISO8601Time(),
    "Format": "JSON",
    "RegionId": "cn-shanghai",
    "SignatureMethod": "HMAC-SHA1",
    "SignatureVersion": "1.0",
    "SignatureNonce": getUniqueNonce(),
  };

  // 步骤1：构造规范化的请求字符串
  var queryString = canonicalizedQuery(queryParamsMap);
  if (queryString.isEmpty) {
    if (kDebugMode) {
      print("构造规范化的请求字符串失败！");
    }
    return aliToken;
  }

  // 步骤2：构造签名字符串
  var method = "GET"; // 发送请求的 HTTP 方法，GET
  var urlPath = "/"; // 请求路径
  var stringToSign = createStringToSign(method, urlPath, queryString);
  if (stringToSign.isEmpty) {
    if (kDebugMode) {
      print("构造签名字符串失败");
    }
    return aliToken;
  }

  // 步骤3：计算签名
  var signature = sign(stringToSign, "$accessKeySecret&");
  if (signature.isEmpty) {
    if (kDebugMode) {
      print("计算签名失败!");
    }
    return aliToken;
  }

  // 步骤4：将签名加入到第1步获取的请求字符串
  var queryStringWithSign = "Signature=$signature&$queryString";
  if (kDebugMode) {
    print("带有签名的请求字符串：$queryStringWithSign");
  }

  // 步骤5：发送HTTP GET请求，获取token
  processGETRequest(queryStringWithSign);

  if (token != null) {
    aliToken = token!;
    if (kDebugMode) {
      print("获取的Token：$token, 有效期时间戳（秒）：$expireTime");
    }
    // 将10位数的时间戳转换为北京时间
    var expireDate = DateTime.fromMillisecondsSinceEpoch(expireTime * 1000);
    if (kDebugMode) {
      print("Token有效期的北京时间：${expireDate.toLocal()}");
    }
  }
  return aliToken;
}
