import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

class ApiBase {
  final Dio _dio;

  ApiBase(this._dio);

  Future<Response> get(String url, {Map<String, dynamic>? headerOptions, Options? otherOptions,CancelToken? cancelToken}) async {
    return _request(
      method: 'GET',
      url: url,
      headerOptions: headerOptions,
      options: otherOptions,
      cancelToken: cancelToken
    );
  }

  Future<Response> post(String url, dynamic data, {Options? options, Map<String, dynamic>? queryParameters,CancelToken? cancelToken}) async {
    return _request(
      method: 'POST',
      url: url,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken
    );
  }

  Future<T?> postAndParse<T>(
    String url,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    Options? options,
    Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken
  }) async {
    final response = await _request(
      method: 'POST',
      url: url,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken
    );

    if (response.statusCode == 200) {
      return fromJson(response.data);
    } else {
      // Handle error and return null or a default value if needed
      return null;
    }
  }

  Future<Response> put(String url, dynamic data, {Options? options,CancelToken? cancelToken}) async {
    return _request(
      method: 'PUT',
      url: url,
      data: data,
      options: options,
      cancelToken: cancelToken
    );
  }

  Future<Response> delete(String url, dynamic data, {Options? options,CancelToken? cancelToken}) async {
    return _request(
      method: 'DELETE',
      url: url,
      data: data,
      options: options,
      cancelToken: cancelToken
    );
  }

  Future<Response> download(String url, String savePath, {ProgressCallback? onReceiveProgress, Map<String, dynamic>? headerOptions,CancelToken? cancelToken}) async {
    return _request(
      method: 'DOWNLOAD',
      url: url,
      savePath: savePath,
      onReceiveProgress: onReceiveProgress,
      headerOptions: headerOptions,
      cancelToken: cancelToken
    );
  }

  Future<Response> _request({
    required String method,
    required String url,
    dynamic data,
    String? savePath,
    ProgressCallback? onReceiveProgress,
    Options? options,
    Map<String, dynamic>? headerOptions,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final requestOptions = Options(
        method: method == 'DOWNLOAD' ? 'GET' : method,
        headers: headerOptions ?? options?.headers,
        responseType: options?.responseType,
        contentType: options?.contentType,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        validateStatus: options?.validateStatus,
        receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
        receiveTimeout: options?.receiveTimeout,
        sendTimeout: options?.sendTimeout,
      );

      final response = method == 'DOWNLOAD'
          ? await _dio.download(url, savePath!,
              onReceiveProgress: onReceiveProgress, options: requestOptions, queryParameters: queryParameters, cancelToken: cancelToken)
          : await _dio.request(url, data: data, options: requestOptions, queryParameters: queryParameters, cancelToken: cancelToken);
      return response;
    } catch (e) {
      return _handleError(url, e);
    }
  }

  Response _handleError(String url, dynamic error) {
    // 构造一个包含错误信息的 Response 对象
    var errorMessage = "Unexpected error occurred";
    int statusCode = 500;

    if (error is DioException) {
      if (error.response != null) {
        return error.response!;
      } else {
        final result = _getDioErrorDetails(error);
        errorMessage = result['message'];
        statusCode = result['statusCode'];
      }
    } else {
      errorMessage = "Unexpected error: $error";
    }

    // 返回包含错误信息的 Response 对象
    return Response(
      requestOptions: RequestOptions(path: url),
      data: {'error': errorMessage},
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _getDioErrorDetails(DioException error) {
    var errorMessage = "Unexpected error occurred";
    int statusCode = 500;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = "Connection Timeout";
        statusCode = 408;
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = "Send Timeout";
        statusCode = 408;
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = "Receive Timeout";
        statusCode = 408;
        break;
      case DioExceptionType.badResponse:
        errorMessage = "Received invalid status code: ${error.response?.statusCode}";
        statusCode = error.response?.statusCode ?? 500;
        break;
      case DioExceptionType.cancel:
        errorMessage = "Request to API server was cancelled";
        statusCode = 499;
        break;
      case DioExceptionType.unknown:
        errorMessage = "Connection to API server failed due to internet connection";
        statusCode = 503;
        break;
      default:
        break;
    }

    return {'url': url, 'message': errorMessage, 'statusCode': statusCode};
  }
}
