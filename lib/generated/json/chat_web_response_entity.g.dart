import 'package:tuitu/generated/json/base/json_convert_content.dart';
import 'package:tuitu/json_models/chat_web_response_entity.dart';

ChatWebResponseEntity $ChatWebResponseEntityFromJson(Map<String, dynamic> json) {
  final ChatWebResponseEntity chatWebResponseEntity = ChatWebResponseEntity();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    chatWebResponseEntity.id = id;
  }
  final String? object = jsonConvert.convert<String>(json['object']);
  if (object != null) {
    chatWebResponseEntity.object = object;
  }
  final int? created = jsonConvert.convert<int>(json['created']);
  if (created != null) {
    chatWebResponseEntity.created = created;
  }
  final String? model = jsonConvert.convert<String>(json['model']);
  if (model != null) {
    chatWebResponseEntity.model = model;
  }
  final ChatWebResponseUsage? usage = jsonConvert.convert<ChatWebResponseUsage>(json['usage']);
  if (usage != null) {
    chatWebResponseEntity.usage = usage;
  }
  final List<ChatWebResponseChoices>? choices = (json['choices'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<ChatWebResponseChoices>(e) as ChatWebResponseChoices).toList();
  if (choices != null) {
    chatWebResponseEntity.choices = choices;
  }
  return chatWebResponseEntity;
}

Map<String, dynamic> $ChatWebResponseEntityToJson(ChatWebResponseEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['object'] = entity.object;
  data['created'] = entity.created;
  data['model'] = entity.model;
  data['usage'] = entity.usage.toJson();
  data['choices'] = entity.choices.map((v) => v.toJson()).toList();
  return data;
}

extension ChatWebResponseEntityExtension on ChatWebResponseEntity {
  ChatWebResponseEntity copyWith({
    String? id,
    String? object,
    int? created,
    String? model,
    ChatWebResponseUsage? usage,
    List<ChatWebResponseChoices>? choices,
  }) {
    return ChatWebResponseEntity()
      ..id = id ?? this.id
      ..object = object ?? this.object
      ..created = created ?? this.created
      ..model = model ?? this.model
      ..usage = usage ?? this.usage
      ..choices = choices ?? this.choices;
  }
}

ChatWebResponseUsage $ChatWebResponseUsageFromJson(Map<String, dynamic> json) {
  final ChatWebResponseUsage chatWebResponseUsage = ChatWebResponseUsage();
  final int? promptTokens = jsonConvert.convert<int>(json['prompt_tokens']);
  if (promptTokens != null) {
    chatWebResponseUsage.promptTokens = promptTokens;
  }
  final int? completionTokens = jsonConvert.convert<int>(json['completion_tokens']);
  if (completionTokens != null) {
    chatWebResponseUsage.completionTokens = completionTokens;
  }
  final int? totalTokens = jsonConvert.convert<int>(json['total_tokens']);
  if (totalTokens != null) {
    chatWebResponseUsage.totalTokens = totalTokens;
  }
  return chatWebResponseUsage;
}

Map<String, dynamic> $ChatWebResponseUsageToJson(ChatWebResponseUsage entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['prompt_tokens'] = entity.promptTokens;
  data['completion_tokens'] = entity.completionTokens;
  data['total_tokens'] = entity.totalTokens;
  return data;
}

extension ChatWebResponseUsageExtension on ChatWebResponseUsage {
  ChatWebResponseUsage copyWith({
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
  }) {
    return ChatWebResponseUsage()
      ..promptTokens = promptTokens ?? this.promptTokens
      ..completionTokens = completionTokens ?? this.completionTokens
      ..totalTokens = totalTokens ?? this.totalTokens;
  }
}

ChatWebResponseChoices $ChatWebResponseChoicesFromJson(Map<String, dynamic> json) {
  final ChatWebResponseChoices chatWebResponseChoices = ChatWebResponseChoices();
  final int? index = jsonConvert.convert<int>(json['index']);
  if (index != null) {
    chatWebResponseChoices.index = index;
  }
  final ChatWebResponseChoicesMessage? message = jsonConvert.convert<ChatWebResponseChoicesMessage>(json['message']);
  if (message != null) {
    chatWebResponseChoices.message = message;
  }
  final dynamic finishReason = json['finish_reason'];
  if (finishReason != null) {
    chatWebResponseChoices.finishReason = finishReason;
  }
  return chatWebResponseChoices;
}

Map<String, dynamic> $ChatWebResponseChoicesToJson(ChatWebResponseChoices entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['index'] = entity.index;
  data['message'] = entity.message.toJson();
  data['finish_reason'] = entity.finishReason;
  return data;
}

extension ChatWebResponseChoicesExtension on ChatWebResponseChoices {
  ChatWebResponseChoices copyWith({
    int? index,
    ChatWebResponseChoicesMessage? message,
    dynamic finishReason,
  }) {
    return ChatWebResponseChoices()
      ..index = index ?? this.index
      ..message = message ?? this.message
      ..finishReason = finishReason ?? this.finishReason;
  }
}

ChatWebResponseChoicesMessage $ChatWebResponseChoicesMessageFromJson(Map<String, dynamic> json) {
  final ChatWebResponseChoicesMessage chatWebResponseChoicesMessage = ChatWebResponseChoicesMessage();
  final String? role = jsonConvert.convert<String>(json['role']);
  if (role != null) {
    chatWebResponseChoicesMessage.role = role;
  }
  final String? content = jsonConvert.convert<String>(json['content']);
  if (content != null) {
    chatWebResponseChoicesMessage.content = content;
  }
  return chatWebResponseChoicesMessage;
}

Map<String, dynamic> $ChatWebResponseChoicesMessageToJson(ChatWebResponseChoicesMessage entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['role'] = entity.role;
  data['content'] = entity.content;
  return data;
}

extension ChatWebResponseChoicesMessageExtension on ChatWebResponseChoicesMessage {
  ChatWebResponseChoicesMessage copyWith({
    String? role,
    String? content,
  }) {
    return ChatWebResponseChoicesMessage()
      ..role = role ?? this.role
      ..content = content ?? this.content;
  }
}