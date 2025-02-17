abstract class IDatabaseHelper {
  Future<dynamic> init();

  Future<dynamic> insert(String tableName, dynamic data);

  Future<dynamic> queryAll(String tableName);

  Future<dynamic> query(String tableName, dynamic data, {dynamic selectInfo, bool isOrdered, String orderInfo});

  Future<dynamic> update(String tableName, dynamic data, {dynamic updateMatchInfo});

  Future<dynamic> delete(String tableName, {Map<String, Object> data = const {}});

  Future<dynamic> signUp(String email, String pwd, Map<String, dynamic> data);

  Future<dynamic> signIn(String email, String pwd);

  Future<dynamic> signOut();

}
