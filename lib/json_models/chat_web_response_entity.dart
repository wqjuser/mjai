import 'package:tuitu/generated/json/base/json_field.dart';
import 'package:tuitu/generated/json/chat_web_response_entity.g.dart';
import 'dart:convert';

@JsonSerializable()
class ChatWebResponseEntity {
  late String id;
  late String object;
  late int created;
  late String model;
  late ChatWebResponseUsage usage;
  late List<ChatWebResponseChoices> choices;

  ChatWebResponseEntity();

  factory ChatWebResponseEntity.fromJson(Map<String, dynamic> json) => $ChatWebResponseEntityFromJson(json);

  Map<String, dynamic> toJson() => $ChatWebResponseEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class ChatWebResponseUsage {
  @JSONField(name: "prompt_tokens")
  late int promptTokens;
  @JSONField(name: "completion_tokens")
  late int completionTokens;
  @JSONField(name: "total_tokens")
  late int totalTokens;

  ChatWebResponseUsage();

  factory ChatWebResponseUsage.fromJson(Map<String, dynamic> json) => $ChatWebResponseUsageFromJson(json);

  Map<String, dynamic> toJson() => $ChatWebResponseUsageToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class ChatWebResponseChoices {
  late int index;
  late ChatWebResponseChoicesMessage message;
  @JSONField(name: "finish_reason")
  dynamic finishReason;

  ChatWebResponseChoices();

  factory ChatWebResponseChoices.fromJson(Map<String, dynamic> json) => $ChatWebResponseChoicesFromJson(json);

  Map<String, dynamic> toJson() => $ChatWebResponseChoicesToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class ChatWebResponseChoicesMessage {
  late String role;
  late String content;

  ChatWebResponseChoicesMessage();

  factory ChatWebResponseChoicesMessage.fromJson(Map<String, dynamic> json) =>
      $ChatWebResponseChoicesMessageFromJson(json);

  Map<String, dynamic> toJson() => $ChatWebResponseChoicesMessageToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
