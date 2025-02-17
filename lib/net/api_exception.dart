class ApiException implements Exception {
  final String? message;
  final Uri? uri;
  final String? method;
  final int? code;
  final dynamic body;

  ApiException({
    this.message,
    this.uri,
    this.method,
    this.code,
    this.body,
  });

  @override
  String toString() {
    return '$message';
  }
}