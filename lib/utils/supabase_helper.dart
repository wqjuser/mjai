import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/utils/common_methods.dart';
import '../config/config.dart';
import '../config/global_params.dart';
import 'database_helper.dart';

class SupabaseHelper extends IDatabaseHelper {
  static final SupabaseHelper _instance = SupabaseHelper._internal();
  SupabaseClient? _client;

  SupabaseHelper._internal();

  factory SupabaseHelper() {
    return _instance;
  }

  /// 获取当前登录用户
  User? get currentUser => _client?.auth.currentUser;

  /// 获取当前用户ID
  String? get currentUserId => currentUser?.id;

  @override
  Future<dynamic> init() async {
    var config = await Config.loadSettings();
    String supabaseUrl = config['supabase_url'] ?? '';
    String supabaseAnonKey = config['supabase_key'] ?? '';
    if (!GlobalParams.isAdminVersion && !GlobalParams.isFreeVersion) {
      supabaseAnonKey = GlobalParams.supabaseAnonKey;
      supabaseUrl = GlobalParams.supabaseUrl;
    }
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      commonPrint('未配置数据库参数，不初始化数据库');
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      //开启实时监听
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 2,
      ),
    );
    _client = Supabase.instance.client;
    return _client;
  }

  @override
  Future<dynamic> insert(String tableName, data) async {
    await _client?.from(tableName).insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String tableName, data,
      {selectInfo,
      bool isOrdered = false,
      String orderInfo = 'id',
      String? ltName,
      dynamic ltValue,
      int limitNum = 0,
      String? iLikeValue,
      String? iLikeName,
      String? containedByName,
      String? orInfo,
      dynamic containedByValue}) async {
    dynamic query = _client?.from(tableName).select(selectInfo ?? '*').match(data);
    // 如果有 ltName 和 ltValue，添加 .lt 条件
    if (ltName != null && ltValue != null) {
      query = query.lt(ltName, ltValue);
    }
    if (orInfo != null) {
      query = query.or(orInfo);
    }
    if (iLikeName != null && iLikeValue != null) {
      query = query.ilike(iLikeName, iLikeValue);
    }
    if (containedByName != null && containedByValue != null) {
      query = query.containedBy(containedByName, containedByValue);
    }
    query = query.order(orderInfo, ascending: isOrdered);
    //如果需要限制数量，添加 .limit 条件
    if (limitNum > 0) {
      query = query.limit(limitNum);
    }

    return await query;
  }

  @override
  Future<dynamic> queryAll(String tableName) async {
    await _client?.from(tableName).select();
  }

  @override
  Future<dynamic> update(String tableName, data, {updateMatchInfo}) async {
    await _client?.from(tableName).update(data).match(updateMatchInfo);
  }

  @override
  Future<dynamic> delete(String tableName, {Map<String, Object> data = const {}}) async {
    await _client?.from(tableName).delete().match(data);
  }

  @override
  Future<AuthResponse> signUp(String email, String pwd, Map<String, dynamic> data) async {
    return await _client!.auth.signUp(email: email, password: pwd, data: data);
  }

  @override
  Future<AuthResponse> signIn(String email, String pwd) async {
    return await _client!.auth.signInWithPassword(email: email, password: pwd);
  }

  @override
  Future signOut() async {
    await _client!.auth.signOut();
  }

  Future updateUser(UserAttributes userAttributes) async {
    //更新用户数据，此方法需要用户登录
    await _client?.auth.updateUser(userAttributes);
  }

  Future<dynamic> resetPasswordForEmail(String email) async {
    //通过邮箱更新用户密码
    final redirectUrl = Uri(scheme: 'https', host: 'password.zxai.fun', path: 'verify').toString();
    await _client?.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  Future updateUserByAdmin(String userId, Map<String, dynamic> data) async {
    //通过管理员更新用户数据
    await _client?.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(
        email: 'new@email.com',
      ),
    );
  }

  Future<dynamic> runRPC(String functionName, Map<String, dynamic> params) async {
    try {
      final response = await _client?.rpc(
        functionName,
        params: params,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to run rpc: $functionName\n$e');
    }
  }

  RealtimeChannel? channel(String s) {
    return _client?.channel(s);
  }
}
