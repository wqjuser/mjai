import 'package:tuitu/generated/json/base/json_convert_content.dart';
import 'package:tuitu/json_models/music_response_entity.dart';

MusicResponseEntity $MusicResponseEntityFromJson(Map<String, dynamic> json) {
  final MusicResponseEntity musicResponseEntity = MusicResponseEntity();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicResponseEntity.id = id;
  }
  final List<MusicResponseClips>? clips = (json['clips'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<MusicResponseClips>(e) as MusicResponseClips).toList();
  if (clips != null) {
    musicResponseEntity.clips = clips;
  }
  final MusicResponseMetadata? metadata = jsonConvert.convert<MusicResponseMetadata>(json['metadata']);
  if (metadata != null) {
    musicResponseEntity.metadata = metadata;
  }
  final String? majorModelVersion = jsonConvert.convert<String>(json['major_model_version']);
  if (majorModelVersion != null) {
    musicResponseEntity.majorModelVersion = majorModelVersion;
  }
  final String? status = jsonConvert.convert<String>(json['status']);
  if (status != null) {
    musicResponseEntity.status = status;
  }
  final String? createdAt = jsonConvert.convert<String>(json['created_at']);
  if (createdAt != null) {
    musicResponseEntity.createdAt = createdAt;
  }
  final int? batchSize = jsonConvert.convert<int>(json['batch_size']);
  if (batchSize != null) {
    musicResponseEntity.batchSize = batchSize;
  }
  return musicResponseEntity;
}

Map<String, dynamic> $MusicResponseEntityToJson(MusicResponseEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['clips'] = entity.clips?.map((v) => v.toJson()).toList();
  data['metadata'] = entity.metadata?.toJson();
  data['major_model_version'] = entity.majorModelVersion;
  data['status'] = entity.status;
  data['created_at'] = entity.createdAt;
  data['batch_size'] = entity.batchSize;
  return data;
}

extension MusicResponseEntityExtension on MusicResponseEntity {
  MusicResponseEntity copyWith({
    String? id,
    List<MusicResponseClips>? clips,
    MusicResponseMetadata? metadata,
    String? majorModelVersion,
    String? status,
    String? createdAt,
    int? batchSize,
  }) {
    return MusicResponseEntity()
      ..id = id ?? this.id
      ..clips = clips ?? this.clips
      ..metadata = metadata ?? this.metadata
      ..majorModelVersion = majorModelVersion ?? this.majorModelVersion
      ..status = status ?? this.status
      ..createdAt = createdAt ?? this.createdAt
      ..batchSize = batchSize ?? this.batchSize;
  }
}

MusicResponseClips $MusicResponseClipsFromJson(Map<String, dynamic> json) {
  final MusicResponseClips musicResponseClips = MusicResponseClips();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicResponseClips.id = id;
  }
  final String? videoUrl = jsonConvert.convert<String>(json['video_url']);
  if (videoUrl != null) {
    musicResponseClips.videoUrl = videoUrl;
  }
  final String? audioUrl = jsonConvert.convert<String>(json['audio_url']);
  if (audioUrl != null) {
    musicResponseClips.audioUrl = audioUrl;
  }
  final dynamic imageUrl = json['image_url'];
  if (imageUrl != null) {
    musicResponseClips.imageUrl = imageUrl;
  }
  final dynamic imageLargeUrl = json['image_large_url'];
  if (imageLargeUrl != null) {
    musicResponseClips.imageLargeUrl = imageLargeUrl;
  }
  final bool? isVideoPending = jsonConvert.convert<bool>(json['is_video_pending']);
  if (isVideoPending != null) {
    musicResponseClips.isVideoPending = isVideoPending;
  }
  final String? majorModelVersion = jsonConvert.convert<String>(json['major_model_version']);
  if (majorModelVersion != null) {
    musicResponseClips.majorModelVersion = majorModelVersion;
  }
  final String? modelName = jsonConvert.convert<String>(json['model_name']);
  if (modelName != null) {
    musicResponseClips.modelName = modelName;
  }
  final MusicResponseClipsMetadata? metadata = jsonConvert.convert<MusicResponseClipsMetadata>(json['metadata']);
  if (metadata != null) {
    musicResponseClips.metadata = metadata;
  }
  final bool? isLiked = jsonConvert.convert<bool>(json['is_liked']);
  if (isLiked != null) {
    musicResponseClips.isLiked = isLiked;
  }
  final String? userId = jsonConvert.convert<String>(json['user_id']);
  if (userId != null) {
    musicResponseClips.userId = userId;
  }
  final String? displayName = jsonConvert.convert<String>(json['display_name']);
  if (displayName != null) {
    musicResponseClips.displayName = displayName;
  }
  final String? handle = jsonConvert.convert<String>(json['handle']);
  if (handle != null) {
    musicResponseClips.handle = handle;
  }
  final bool? isHandleUpdated = jsonConvert.convert<bool>(json['is_handle_updated']);
  if (isHandleUpdated != null) {
    musicResponseClips.isHandleUpdated = isHandleUpdated;
  }
  final String? avatarImageUrl = jsonConvert.convert<String>(json['avatar_image_url']);
  if (avatarImageUrl != null) {
    musicResponseClips.avatarImageUrl = avatarImageUrl;
  }
  final bool? isTrashed = jsonConvert.convert<bool>(json['is_trashed']);
  if (isTrashed != null) {
    musicResponseClips.isTrashed = isTrashed;
  }
  final dynamic reaction = json['reaction'];
  if (reaction != null) {
    musicResponseClips.reaction = reaction;
  }
  final String? createdAt = jsonConvert.convert<String>(json['created_at']);
  if (createdAt != null) {
    musicResponseClips.createdAt = createdAt;
  }
  final String? status = jsonConvert.convert<String>(json['status']);
  if (status != null) {
    musicResponseClips.status = status;
  }
  final String? title = jsonConvert.convert<String>(json['title']);
  if (title != null) {
    musicResponseClips.title = title;
  }
  final int? playCount = jsonConvert.convert<int>(json['play_count']);
  if (playCount != null) {
    musicResponseClips.playCount = playCount;
  }
  final int? upvoteCount = jsonConvert.convert<int>(json['upvote_count']);
  if (upvoteCount != null) {
    musicResponseClips.upvoteCount = upvoteCount;
  }
  final bool? isPublic = jsonConvert.convert<bool>(json['is_public']);
  if (isPublic != null) {
    musicResponseClips.isPublic = isPublic;
  }
  return musicResponseClips;
}

Map<String, dynamic> $MusicResponseClipsToJson(MusicResponseClips entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['video_url'] = entity.videoUrl;
  data['audio_url'] = entity.audioUrl;
  data['image_url'] = entity.imageUrl;
  data['image_large_url'] = entity.imageLargeUrl;
  data['is_video_pending'] = entity.isVideoPending;
  data['major_model_version'] = entity.majorModelVersion;
  data['model_name'] = entity.modelName;
  data['metadata'] = entity.metadata?.toJson();
  data['is_liked'] = entity.isLiked;
  data['user_id'] = entity.userId;
  data['display_name'] = entity.displayName;
  data['handle'] = entity.handle;
  data['is_handle_updated'] = entity.isHandleUpdated;
  data['avatar_image_url'] = entity.avatarImageUrl;
  data['is_trashed'] = entity.isTrashed;
  data['reaction'] = entity.reaction;
  data['created_at'] = entity.createdAt;
  data['status'] = entity.status;
  data['title'] = entity.title;
  data['play_count'] = entity.playCount;
  data['upvote_count'] = entity.upvoteCount;
  data['is_public'] = entity.isPublic;
  return data;
}

extension MusicResponseClipsExtension on MusicResponseClips {
  MusicResponseClips copyWith({
    String? id,
    String? videoUrl,
    String? audioUrl,
    dynamic imageUrl,
    dynamic imageLargeUrl,
    bool? isVideoPending,
    String? majorModelVersion,
    String? modelName,
    MusicResponseClipsMetadata? metadata,
    bool? isLiked,
    String? userId,
    String? displayName,
    String? handle,
    bool? isHandleUpdated,
    String? avatarImageUrl,
    bool? isTrashed,
    dynamic reaction,
    String? createdAt,
    String? status,
    String? title,
    int? playCount,
    int? upvoteCount,
    bool? isPublic,
  }) {
    return MusicResponseClips()
      ..id = id ?? this.id
      ..videoUrl = videoUrl ?? this.videoUrl
      ..audioUrl = audioUrl ?? this.audioUrl
      ..imageUrl = imageUrl ?? this.imageUrl
      ..imageLargeUrl = imageLargeUrl ?? this.imageLargeUrl
      ..isVideoPending = isVideoPending ?? this.isVideoPending
      ..majorModelVersion = majorModelVersion ?? this.majorModelVersion
      ..modelName = modelName ?? this.modelName
      ..metadata = metadata ?? this.metadata
      ..isLiked = isLiked ?? this.isLiked
      ..userId = userId ?? this.userId
      ..displayName = displayName ?? this.displayName
      ..handle = handle ?? this.handle
      ..isHandleUpdated = isHandleUpdated ?? this.isHandleUpdated
      ..avatarImageUrl = avatarImageUrl ?? this.avatarImageUrl
      ..isTrashed = isTrashed ?? this.isTrashed
      ..reaction = reaction ?? this.reaction
      ..createdAt = createdAt ?? this.createdAt
      ..status = status ?? this.status
      ..title = title ?? this.title
      ..playCount = playCount ?? this.playCount
      ..upvoteCount = upvoteCount ?? this.upvoteCount
      ..isPublic = isPublic ?? this.isPublic;
  }
}

MusicResponseClipsMetadata $MusicResponseClipsMetadataFromJson(Map<String, dynamic> json) {
  final MusicResponseClipsMetadata musicResponseClipsMetadata = MusicResponseClipsMetadata();
  final String? tags = jsonConvert.convert<String>(json['tags']);
  if (tags != null) {
    musicResponseClipsMetadata.tags = tags;
  }
  final String? prompt = jsonConvert.convert<String>(json['prompt']);
  if (prompt != null) {
    musicResponseClipsMetadata.prompt = prompt;
  }
  final dynamic gptDescriptionPrompt = json['gpt_description_prompt'];
  if (gptDescriptionPrompt != null) {
    musicResponseClipsMetadata.gptDescriptionPrompt = gptDescriptionPrompt;
  }
  final String? audioPromptId = jsonConvert.convert<String>(json['audio_prompt_id']);
  if (audioPromptId != null) {
    musicResponseClipsMetadata.audioPromptId = audioPromptId;
  }
  final List<MusicResponseClipsMetadataHistory>? history = (json['history'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<MusicResponseClipsMetadataHistory>(e) as MusicResponseClipsMetadataHistory).toList();
  if (history != null) {
    musicResponseClipsMetadata.history = history;
  }
  final dynamic concatHistory = json['concat_history'];
  if (concatHistory != null) {
    musicResponseClipsMetadata.concatHistory = concatHistory;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicResponseClipsMetadata.type = type;
  }
  final dynamic duration = json['duration'];
  if (duration != null) {
    musicResponseClipsMetadata.duration = duration;
  }
  final dynamic refundCredits = json['refund_credits'];
  if (refundCredits != null) {
    musicResponseClipsMetadata.refundCredits = refundCredits;
  }
  final bool? stream = jsonConvert.convert<bool>(json['stream']);
  if (stream != null) {
    musicResponseClipsMetadata.stream = stream;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicResponseClipsMetadata.infill = infill;
  }
  final bool? hasVocal = jsonConvert.convert<bool>(json['has_vocal']);
  if (hasVocal != null) {
    musicResponseClipsMetadata.hasVocal = hasVocal;
  }
  final bool? isAudioUploadTosAccepted = jsonConvert.convert<bool>(json['is_audio_upload_tos_accepted']);
  if (isAudioUploadTosAccepted != null) {
    musicResponseClipsMetadata.isAudioUploadTosAccepted = isAudioUploadTosAccepted;
  }
  final dynamic errorType = json['error_type'];
  if (errorType != null) {
    musicResponseClipsMetadata.errorType = errorType;
  }
  final dynamic errorMessage = json['error_message'];
  if (errorMessage != null) {
    musicResponseClipsMetadata.errorMessage = errorMessage;
  }
  return musicResponseClipsMetadata;
}

Map<String, dynamic> $MusicResponseClipsMetadataToJson(MusicResponseClipsMetadata entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['tags'] = entity.tags;
  data['prompt'] = entity.prompt;
  data['gpt_description_prompt'] = entity.gptDescriptionPrompt;
  data['audio_prompt_id'] = entity.audioPromptId;
  data['history'] = entity.history?.map((v) => v.toJson()).toList();
  data['concat_history'] = entity.concatHistory;
  data['type'] = entity.type;
  data['duration'] = entity.duration;
  data['refund_credits'] = entity.refundCredits;
  data['stream'] = entity.stream;
  data['infill'] = entity.infill;
  data['has_vocal'] = entity.hasVocal;
  data['is_audio_upload_tos_accepted'] = entity.isAudioUploadTosAccepted;
  data['error_type'] = entity.errorType;
  data['error_message'] = entity.errorMessage;
  return data;
}

extension MusicResponseClipsMetadataExtension on MusicResponseClipsMetadata {
  MusicResponseClipsMetadata copyWith({
    String? tags,
    String? prompt,
    dynamic gptDescriptionPrompt,
    String? audioPromptId,
    List<MusicResponseClipsMetadataHistory>? history,
    dynamic concatHistory,
    String? type,
    dynamic duration,
    dynamic refundCredits,
    bool? stream,
    bool? infill,
    bool? hasVocal,
    bool? isAudioUploadTosAccepted,
    dynamic errorType,
    dynamic errorMessage,
  }) {
    return MusicResponseClipsMetadata()
      ..tags = tags ?? this.tags
      ..prompt = prompt ?? this.prompt
      ..gptDescriptionPrompt = gptDescriptionPrompt ?? this.gptDescriptionPrompt
      ..audioPromptId = audioPromptId ?? this.audioPromptId
      ..history = history ?? this.history
      ..concatHistory = concatHistory ?? this.concatHistory
      ..type = type ?? this.type
      ..duration = duration ?? this.duration
      ..refundCredits = refundCredits ?? this.refundCredits
      ..stream = stream ?? this.stream
      ..infill = infill ?? this.infill
      ..hasVocal = hasVocal ?? this.hasVocal
      ..isAudioUploadTosAccepted = isAudioUploadTosAccepted ?? this.isAudioUploadTosAccepted
      ..errorType = errorType ?? this.errorType
      ..errorMessage = errorMessage ?? this.errorMessage;
  }
}

MusicResponseClipsMetadataHistory $MusicResponseClipsMetadataHistoryFromJson(Map<String, dynamic> json) {
  final MusicResponseClipsMetadataHistory musicResponseClipsMetadataHistory = MusicResponseClipsMetadataHistory();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicResponseClipsMetadataHistory.id = id;
  }
  final double? continueAt = jsonConvert.convert<double>(json['continue_at']);
  if (continueAt != null) {
    musicResponseClipsMetadataHistory.continueAt = continueAt;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicResponseClipsMetadataHistory.type = type;
  }
  final String? source = jsonConvert.convert<String>(json['source']);
  if (source != null) {
    musicResponseClipsMetadataHistory.source = source;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicResponseClipsMetadataHistory.infill = infill;
  }
  return musicResponseClipsMetadataHistory;
}

Map<String, dynamic> $MusicResponseClipsMetadataHistoryToJson(MusicResponseClipsMetadataHistory entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['continue_at'] = entity.continueAt;
  data['type'] = entity.type;
  data['source'] = entity.source;
  data['infill'] = entity.infill;
  return data;
}

extension MusicResponseClipsMetadataHistoryExtension on MusicResponseClipsMetadataHistory {
  MusicResponseClipsMetadataHistory copyWith({
    String? id,
    double? continueAt,
    String? type,
    String? source,
    bool? infill,
  }) {
    return MusicResponseClipsMetadataHistory()
      ..id = id ?? this.id
      ..continueAt = continueAt ?? this.continueAt
      ..type = type ?? this.type
      ..source = source ?? this.source
      ..infill = infill ?? this.infill;
  }
}

MusicResponseMetadata $MusicResponseMetadataFromJson(Map<String, dynamic> json) {
  final MusicResponseMetadata musicResponseMetadata = MusicResponseMetadata();
  final String? tags = jsonConvert.convert<String>(json['tags']);
  if (tags != null) {
    musicResponseMetadata.tags = tags;
  }
  final String? prompt = jsonConvert.convert<String>(json['prompt']);
  if (prompt != null) {
    musicResponseMetadata.prompt = prompt;
  }
  final dynamic gptDescriptionPrompt = json['gpt_description_prompt'];
  if (gptDescriptionPrompt != null) {
    musicResponseMetadata.gptDescriptionPrompt = gptDescriptionPrompt;
  }
  final String? audioPromptId = jsonConvert.convert<String>(json['audio_prompt_id']);
  if (audioPromptId != null) {
    musicResponseMetadata.audioPromptId = audioPromptId;
  }
  final List<MusicResponseMetadataHistory>? history = (json['history'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<MusicResponseMetadataHistory>(e) as MusicResponseMetadataHistory).toList();
  if (history != null) {
    musicResponseMetadata.history = history;
  }
  final dynamic concatHistory = json['concat_history'];
  if (concatHistory != null) {
    musicResponseMetadata.concatHistory = concatHistory;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicResponseMetadata.type = type;
  }
  final dynamic duration = json['duration'];
  if (duration != null) {
    musicResponseMetadata.duration = duration;
  }
  final dynamic refundCredits = json['refund_credits'];
  if (refundCredits != null) {
    musicResponseMetadata.refundCredits = refundCredits;
  }
  final bool? stream = jsonConvert.convert<bool>(json['stream']);
  if (stream != null) {
    musicResponseMetadata.stream = stream;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicResponseMetadata.infill = infill;
  }
  final bool? hasVocal = jsonConvert.convert<bool>(json['has_vocal']);
  if (hasVocal != null) {
    musicResponseMetadata.hasVocal = hasVocal;
  }
  final bool? isAudioUploadTosAccepted = jsonConvert.convert<bool>(json['is_audio_upload_tos_accepted']);
  if (isAudioUploadTosAccepted != null) {
    musicResponseMetadata.isAudioUploadTosAccepted = isAudioUploadTosAccepted;
  }
  final dynamic errorType = json['error_type'];
  if (errorType != null) {
    musicResponseMetadata.errorType = errorType;
  }
  final dynamic errorMessage = json['error_message'];
  if (errorMessage != null) {
    musicResponseMetadata.errorMessage = errorMessage;
  }
  return musicResponseMetadata;
}

Map<String, dynamic> $MusicResponseMetadataToJson(MusicResponseMetadata entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['tags'] = entity.tags;
  data['prompt'] = entity.prompt;
  data['gpt_description_prompt'] = entity.gptDescriptionPrompt;
  data['audio_prompt_id'] = entity.audioPromptId;
  data['history'] = entity.history?.map((v) => v.toJson()).toList();
  data['concat_history'] = entity.concatHistory;
  data['type'] = entity.type;
  data['duration'] = entity.duration;
  data['refund_credits'] = entity.refundCredits;
  data['stream'] = entity.stream;
  data['infill'] = entity.infill;
  data['has_vocal'] = entity.hasVocal;
  data['is_audio_upload_tos_accepted'] = entity.isAudioUploadTosAccepted;
  data['error_type'] = entity.errorType;
  data['error_message'] = entity.errorMessage;
  return data;
}

extension MusicResponseMetadataExtension on MusicResponseMetadata {
  MusicResponseMetadata copyWith({
    String? tags,
    String? prompt,
    dynamic gptDescriptionPrompt,
    String? audioPromptId,
    List<MusicResponseMetadataHistory>? history,
    dynamic concatHistory,
    String? type,
    dynamic duration,
    dynamic refundCredits,
    bool? stream,
    bool? infill,
    bool? hasVocal,
    bool? isAudioUploadTosAccepted,
    dynamic errorType,
    dynamic errorMessage,
  }) {
    return MusicResponseMetadata()
      ..tags = tags ?? this.tags
      ..prompt = prompt ?? this.prompt
      ..gptDescriptionPrompt = gptDescriptionPrompt ?? this.gptDescriptionPrompt
      ..audioPromptId = audioPromptId ?? this.audioPromptId
      ..history = history ?? this.history
      ..concatHistory = concatHistory ?? this.concatHistory
      ..type = type ?? this.type
      ..duration = duration ?? this.duration
      ..refundCredits = refundCredits ?? this.refundCredits
      ..stream = stream ?? this.stream
      ..infill = infill ?? this.infill
      ..hasVocal = hasVocal ?? this.hasVocal
      ..isAudioUploadTosAccepted = isAudioUploadTosAccepted ?? this.isAudioUploadTosAccepted
      ..errorType = errorType ?? this.errorType
      ..errorMessage = errorMessage ?? this.errorMessage;
  }
}

MusicResponseMetadataHistory $MusicResponseMetadataHistoryFromJson(Map<String, dynamic> json) {
  final MusicResponseMetadataHistory musicResponseMetadataHistory = MusicResponseMetadataHistory();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicResponseMetadataHistory.id = id;
  }
  final double? continueAt = jsonConvert.convert<double>(json['continue_at']);
  if (continueAt != null) {
    musicResponseMetadataHistory.continueAt = continueAt;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicResponseMetadataHistory.type = type;
  }
  final String? source = jsonConvert.convert<String>(json['source']);
  if (source != null) {
    musicResponseMetadataHistory.source = source;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicResponseMetadataHistory.infill = infill;
  }
  return musicResponseMetadataHistory;
}

Map<String, dynamic> $MusicResponseMetadataHistoryToJson(MusicResponseMetadataHistory entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['continue_at'] = entity.continueAt;
  data['type'] = entity.type;
  data['source'] = entity.source;
  data['infill'] = entity.infill;
  return data;
}

extension MusicResponseMetadataHistoryExtension on MusicResponseMetadataHistory {
  MusicResponseMetadataHistory copyWith({
    String? id,
    double? continueAt,
    String? type,
    String? source,
    bool? infill,
  }) {
    return MusicResponseMetadataHistory()
      ..id = id ?? this.id
      ..continueAt = continueAt ?? this.continueAt
      ..type = type ?? this.type
      ..source = source ?? this.source
      ..infill = infill ?? this.infill;
  }
}