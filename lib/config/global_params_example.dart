import 'package:flutter/material.dart';

class GlobalParams {
  static Color themeColor = Colors.lightBlue; //默认主题色
  static String chatBaseUrl = 'xxx'; //自部署的聊天网页地址，目前已经没用了
  static String chatPageUrl = 'xxx'; //同上
  static String aiChatBaseUrl = 'xxx'; //同上
  static bool isAdminVersion = true; //指定打包是否为管理员版本，不可与下面的值同为true
  static bool isFreeVersion = false; //指定打包版本是否为免费版本，不可与上面的值同为true，这两个值同为false的时候，打包为普通版本
  static String filesUrl = isFreeVersion
      ? 'https://telegraph-image-6mz.pages.dev' //免费版的图床地址
      : isAdminVersion || !isFreeVersion
          ? 'xxxx' // 付费版的oss地址，软件使用的阿里云的oss，请阅读阿里云官方oss文档了解如何配置oss
          : 'xxxx'; // 同上
  static String version = '1.6.3'; //打包的版本号
  static String mjApiUrl = 'xxx'; //MJ API的地址 请自行部署https://github.com/trueai-org/midjourney-proxy
  static String mjApiSecret = 'xxx'; //MJ API的鉴权key 如果不配置不需要填写
  static String supabaseUrl = 'xxx'; //supabase数据库url
  static String supabaseAnonKey = 'xxx'; //supabase数据库的anon key
  static Map<String, dynamic> zpaiHeaders = {"alg": "HS256", "sign_type": "SIGN"}; //zpai的请求头
  static String instructionsUrl = 'xxx'; //软件说明书地址
  static String qaBaseUrl = 'https://openapi.youdao.com'; //qanything请求地址
  static Map<String, dynamic> lumaCommonHeaders = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0(Macintosh;U;IntelMacOSX10_6_8;en-us)AppleWebKit/534.50(KHTML,likeGecko)Version/5.1Safari/534.50",
    "Referer": "https://lumalabs.ai/",
    "Origin": "https://lumalabs.ai",
  }; //luma网页端请求的请求头，目前无效了
  static Map<String, dynamic> lumaUploadHeaders = {
    'Content-Type': 'image/*',
    'Referer': 'https://lumalabs.ai/',
    'Origin': 'https://lumalabs.ai'
  }; //luma上传文件的请求头，目前无效了
  static String lumaLabsInternalUrl =
      'https://internal-api.virginia.labs.lumalabs.ai/api/photon/v1/generations/'; //luma官网的api请求地址
  static String sunoMusicBaseUrl = 'https://api.sunoaiapi.com/api/v1/'; //suno音乐的api请求地址
  static String zhipuBaseUrl = 'https://open.bigmodel.cn/api/paas/v4/'; //zhipu的api请求地址
  static List<Map<String, dynamic>> aiModels = []; //ai模型列表
  static List<Map<String, dynamic>> menus = []; //菜单列表
}
