import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'api_exception.dart';

class ChatRequest {
  Future<ApiException> _handleError(dynamic error, String url) async {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 503;

      if (error.response?.data != null) {
        try {
          if (error.response!.data is ResponseBody) {
            final responseBody = error.response!.data as ResponseBody;
            final List<int> bytes = [];

            await for (final chunk in responseBody.stream) {
              bytes.addAll(chunk);
            }
            final errorBody = utf8.decode(bytes);

            try {
              final parsedBody = jsonDecode(errorBody);
              String errorMessage = '';
              dynamic originalBody = parsedBody; // 保存完整的解析后的JSON

              // 提取错误消息但保留原始body
              if (parsedBody is Map && parsedBody.containsKey('error')) {
                if (parsedBody['error'] is Map) {
                  errorMessage = parsedBody['error']['message'] ?? '';
                } else {
                  errorMessage = parsedBody['error'] ?? '';
                }
              }

              return ApiException(
                message: errorMessage.isNotEmpty ? errorMessage : (error.message ?? 'Unknown error'),
                uri: Uri.parse(url),
                method: 'POST',
                code: statusCode,
                body: originalBody, // 使用完整的JSON对象
              );
            } catch (parseError) {
              return ApiException(
                message: errorBody,
                uri: Uri.parse(url),
                method: 'POST',
                code: statusCode,
                body: {'error': errorBody}, // 如果解析失败，将原始内容包装在error对象中
              );
            }
          }
        } catch (streamError) {
          return ApiException(
            message: error.message ?? 'Error processing response',
            uri: Uri.parse(url),
            method: 'POST',
            code: statusCode,
            body: {'error': error.toString()},
          );
        }
      }
    }

    // 默认错误处理
    final errorMessage = error.toString();
    return ApiException(
      message: errorMessage,
      uri: Uri.parse(url),
      method: 'POST',
      code: 503,
      body: {
        'error': {'message': errorMessage}
      }, // 保持一致的错误格式
    );
  }

  Future<void> handleStreamRequest({
    required String url,
    required Map<String, dynamic> requestBody,
    Map<String, String>? headers,
    required Function(String) onMessage,
    required Function(ApiException) onError,
    required Function() onDone,
    StreamSubscription? chatStreamSubscription,
    int maxRetries = 3,
  }) async {
    final Dio myDio = Dio();
    try {
      final response = await myDio.post<ResponseBody>(
        url,
        data: jsonEncode(requestBody),
        options: Options(
          responseType: ResponseType.stream,
          headers: headers ?? {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 100),
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        final apiError = await _handleError(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ),
          url,
        );
        throw apiError;
      }

      bool isFirstMessage = true;
      bool isFirstReasoningMessage = true; // 标记是否在思考过程中
      bool isInReasoningMode = false; // 标记是否在思考过程中
      String reasoningBuffer = ''; // 用于存储完整的思考内容
      String lastSentReasoning = ''; // 用于记录上次发送的思考内容

      chatStreamSubscription =
          response.data!.stream.map((Uint8List data) => data.toList()).transform(utf8.decoder).transform(const LineSplitter()).listen(
        (data) {
          if (data.startsWith("data: ")) {
            data = data.substring(6).trimRight();
          }
          if (data.isEmpty || data == "[DONE]") {
            return;
          }
          try {
            var jsonData = jsonDecode(data);
            if (jsonData['choices'][0]['delta'] != null) {
              var content = jsonData['choices'][0]['delta']['content'];
              //这里是deepseek的思考过程考虑是否要展示
              var reasoningContent = jsonData['choices'][0]['delta']['reasoning_content'];
              if (reasoningContent != null && reasoningContent.isNotEmpty) {
                if (isFirstReasoningMessage) {
                  isFirstReasoningMessage = false;
                  onMessage('\n> '); // 第一条消息添加引用符号
                } else if (reasoningContent.contains('\n')) {
                  reasoningContent = reasoningContent.replaceAll('\n', '\n> ');
                }
                onMessage(reasoningContent);
                isFirstMessage = true;
              }

              if (content != null && content.isNotEmpty) {
                if (content.trim().startsWith('> Reasoning') || content.trim().startsWith('<think>')) {
                  // 进入思考模式
                  isInReasoningMode = true;
                  reasoningBuffer = '> '; // 初始化思考内容缓冲区
                  lastSentReasoning = '> ';
                  onMessage('\n> '); // 发送初始引用符号
                } else if ((content.contains('seconds') || content.contains('</think>')) && isInReasoningMode) {
                  // 思考内容结束
                  isInReasoningMode = false;
                  reasoningBuffer = '';
                  lastSentReasoning = '';
                  onMessage('\n\n'); // 添加额外的换行
                  isFirstMessage = true;
                } else if (isInReasoningMode) {
                  // 在思考模式中，累积内容并只发送增量
                  reasoningBuffer += content;
                  String formattedReasoning = reasoningBuffer;
                  if (formattedReasoning.contains('\n')) {
                    formattedReasoning = formattedReasoning.replaceAll('\n', '\n> ');
                  }
                  // 计算并发送增量内容
                  String incrementalContent = formattedReasoning.substring(lastSentReasoning.length);
                  if (incrementalContent.isNotEmpty) {
                    onMessage(incrementalContent);
                    lastSentReasoning = formattedReasoning;
                  }
                } else {
                  // 普通回复内容
                  onMessage(isFirstMessage ? '\n\n$content' : content);
                  isFirstMessage = false;
                }
              }
            }
          } catch (e) {
            onError(ApiException(
              message: 'JSON parsing error: $e',
              uri: Uri.parse(url),
              method: 'POST',
              code: 422,
              body: data,
            ));
          }
        },
        onError: (error) async {
          final apiError = await _handleError(error, url);
          onError(apiError);
          chatStreamSubscription?.cancel();
        },
        onDone: () {
          onDone();
          chatStreamSubscription?.cancel();
        },
        cancelOnError: true,
      );
    } catch (e) {
      final apiError = await _handleError(e, url);
      onError(apiError);
    }
  }

  // 新增的非流式请求方法
  Future<Map<String, dynamic>> handleRequest({
    required String url,
    required Map<String, dynamic> requestBody,
    Map<String, String>? headers,
    int maxRetries = 3,
  }) async {
    final Dio myDio = Dio();
    try {
      final response = await myDio.post(
        url,
        data: jsonEncode(requestBody),
        options: Options(
          headers: headers ??
              {
                'Content-Type': 'application/json',
              },
          sendTimeout: const Duration(seconds: 100),
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        final apiError = await _handleError(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ),
          url,
        );
        throw apiError;
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          return jsonDecode(response.data);
        } catch (e) {
          throw ApiException(
            message: 'Invalid JSON response',
            uri: Uri.parse(url),
            method: 'POST',
            code: 422,
            body: response.data,
          );
        }
      } else {
        throw ApiException(
          message: 'Unexpected response type',
          uri: Uri.parse(url),
          method: 'POST',
          code: 422,
          body: response.data,
        );
      }
    } catch (e) {
      final apiError = await _handleError(e, url);
      throw apiError;
    }
  }
}
