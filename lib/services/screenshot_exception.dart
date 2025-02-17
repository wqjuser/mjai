class ScreenshotException implements Exception {
  final String message;

  ScreenshotException(this.message);

  @override
  String toString() => 'ScreenshotException: $message';
}