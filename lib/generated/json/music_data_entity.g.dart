import 'package:tuitu/generated/json/base/json_convert_content.dart';
import 'package:tuitu/json_models/music_data_entity.dart';

MusicDataEntity $MusicDataEntityFromJson(Map<String, dynamic> json) {
  final MusicDataEntity musicDataEntity = MusicDataEntity();
  final List<MusicDataClips>? clips = (json['clips'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<MusicDataClips>(e) as MusicDataClips).toList();
  if (clips != null) {
    musicDataEntity.clips = clips;
  }
  final int? numTotalResults = jsonConvert.convert<int>(json['num_total_results']);
  if (numTotalResults != null) {
    musicDataEntity.numTotalResults = numTotalResults;
  }
  final int? currentPage = jsonConvert.convert<int>(json['current_page']);
  if (currentPage != null) {
    musicDataEntity.currentPage = currentPage;
  }
  return musicDataEntity;
}

Map<String, dynamic> $MusicDataEntityToJson(MusicDataEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['clips'] = entity.clips?.map((v) => v.toJson()).toList();
  data['num_total_results'] = entity.numTotalResults;
  data['current_page'] = entity.currentPage;
  return data;
}

extension MusicDataEntityExtension on MusicDataEntity {
  MusicDataEntity copyWith({
    List<MusicDataClips>? clips,
    int? numTotalResults,
    int? currentPage,
  }) {
    return MusicDataEntity()
      ..clips = clips ?? this.clips
      ..numTotalResults = numTotalResults ?? this.numTotalResults
      ..currentPage = currentPage ?? this.currentPage;
  }
}

MusicDataClips $MusicDataClipsFromJson(Map<String, dynamic> json) {
  final MusicDataClips musicDataClips = MusicDataClips();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicDataClips.id = id;
  }
  final String? videoUrl = jsonConvert.convert<String>(json['video_url']);
  if (videoUrl != null) {
    musicDataClips.videoUrl = videoUrl;
  }
  final String? audioUrl = jsonConvert.convert<String>(json['audio_url']);
  if (audioUrl != null) {
    musicDataClips.audioUrl = audioUrl;
  }
  final String? imageUrl = jsonConvert.convert<String>(json['image_url']);
  if (imageUrl != null) {
    musicDataClips.imageUrl = imageUrl;
  }
  final String? imageLargeUrl = jsonConvert.convert<String>(json['image_large_url']);
  if (imageLargeUrl != null) {
    musicDataClips.imageLargeUrl = imageLargeUrl;
  }
  final bool? isVideoPending = jsonConvert.convert<bool>(json['is_video_pending']);
  if (isVideoPending != null) {
    musicDataClips.isVideoPending = isVideoPending;
  }
  final String? majorModelVersion = jsonConvert.convert<String>(json['major_model_version']);
  if (majorModelVersion != null) {
    musicDataClips.majorModelVersion = majorModelVersion;
  }
  final String? modelName = jsonConvert.convert<String>(json['model_name']);
  if (modelName != null) {
    musicDataClips.modelName = modelName;
  }
  final MusicDataClipsMetadata? metadata = jsonConvert.convert<MusicDataClipsMetadata>(json['metadata']);
  if (metadata != null) {
    musicDataClips.metadata = metadata;
  }
  final bool? isLiked = jsonConvert.convert<bool>(json['is_liked']);
  if (isLiked != null) {
    musicDataClips.isLiked = isLiked;
  }
  final String? userId = jsonConvert.convert<String>(json['user_id']);
  if (userId != null) {
    musicDataClips.userId = userId;
  }
  final String? displayName = jsonConvert.convert<String>(json['display_name']);
  if (displayName != null) {
    musicDataClips.displayName = displayName;
  }
  final String? handle = jsonConvert.convert<String>(json['handle']);
  if (handle != null) {
    musicDataClips.handle = handle;
  }
  final bool? isHandleUpdated = jsonConvert.convert<bool>(json['is_handle_updated']);
  if (isHandleUpdated != null) {
    musicDataClips.isHandleUpdated = isHandleUpdated;
  }
  final String? avatarImageUrl = jsonConvert.convert<String>(json['avatar_image_url']);
  if (avatarImageUrl != null) {
    musicDataClips.avatarImageUrl = avatarImageUrl;
  }
  final bool? isTrashed = jsonConvert.convert<bool>(json['is_trashed']);
  if (isTrashed != null) {
    musicDataClips.isTrashed = isTrashed;
  }
  final dynamic reaction = json['reaction'];
  if (reaction != null) {
    musicDataClips.reaction = reaction;
  }
  final String? createdAt = jsonConvert.convert<String>(json['created_at']);
  if (createdAt != null) {
    musicDataClips.createdAt = createdAt;
  }
  final String? status = jsonConvert.convert<String>(json['status']);
  if (status != null) {
    musicDataClips.status = status;
  }
  final String? title = jsonConvert.convert<String>(json['title']);
  if (title != null) {
    musicDataClips.title = title;
  }
  final int? playCount = jsonConvert.convert<int>(json['play_count']);
  if (playCount != null) {
    musicDataClips.playCount = playCount;
  }
  final int? upvoteCount = jsonConvert.convert<int>(json['upvote_count']);
  if (upvoteCount != null) {
    musicDataClips.upvoteCount = upvoteCount;
  }
  final bool? isPublic = jsonConvert.convert<bool>(json['is_public']);
  if (isPublic != null) {
    musicDataClips.isPublic = isPublic;
  }
  return musicDataClips;
}

Map<String, dynamic> $MusicDataClipsToJson(MusicDataClips entity) {
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

extension MusicDataClipsExtension on MusicDataClips {
  MusicDataClips copyWith({
    String? id,
    String? videoUrl,
    String? audioUrl,
    String? imageUrl,
    String? imageLargeUrl,
    bool? isVideoPending,
    String? majorModelVersion,
    String? modelName,
    MusicDataClipsMetadata? metadata,
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
    return MusicDataClips()
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

MusicDataClipsMetadata $MusicDataClipsMetadataFromJson(Map<String, dynamic> json) {
  final MusicDataClipsMetadata musicDataClipsMetadata = MusicDataClipsMetadata();
  final String? tags = jsonConvert.convert<String>(json['tags']);
  if (tags != null) {
    musicDataClipsMetadata.tags = tags;
  }
  final String? prompt = jsonConvert.convert<String>(json['prompt']);
  if (prompt != null) {
    musicDataClipsMetadata.prompt = prompt;
  }
  final dynamic gptDescriptionPrompt = json['gpt_description_prompt'];
  if (gptDescriptionPrompt != null) {
    musicDataClipsMetadata.gptDescriptionPrompt = gptDescriptionPrompt;
  }
  final String? audioPromptId = jsonConvert.convert<String>(json['audio_prompt_id']);
  if (audioPromptId != null) {
    musicDataClipsMetadata.audioPromptId = audioPromptId;
  }
  final List<MusicDataClipsMetadataHistory>? history = (json['history'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<MusicDataClipsMetadataHistory>(e) as MusicDataClipsMetadataHistory).toList();
  if (history != null) {
    musicDataClipsMetadata.history = history;
  }
  final dynamic concatHistory = json['concat_history'];
  if (concatHistory != null) {
    musicDataClipsMetadata.concatHistory = concatHistory;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicDataClipsMetadata.type = type;
  }
  final int? duration = jsonConvert.convert<int>(json['duration']);
  if (duration != null) {
    musicDataClipsMetadata.duration = duration;
  }
  final bool? refundCredits = jsonConvert.convert<bool>(json['refund_credits']);
  if (refundCredits != null) {
    musicDataClipsMetadata.refundCredits = refundCredits;
  }
  final bool? stream = jsonConvert.convert<bool>(json['stream']);
  if (stream != null) {
    musicDataClipsMetadata.stream = stream;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicDataClipsMetadata.infill = infill;
  }
  final bool? hasVocal = jsonConvert.convert<bool>(json['has_vocal']);
  if (hasVocal != null) {
    musicDataClipsMetadata.hasVocal = hasVocal;
  }
  final bool? isAudioUploadTosAccepted = jsonConvert.convert<bool>(json['is_audio_upload_tos_accepted']);
  if (isAudioUploadTosAccepted != null) {
    musicDataClipsMetadata.isAudioUploadTosAccepted = isAudioUploadTosAccepted;
  }
  final dynamic errorType = json['error_type'];
  if (errorType != null) {
    musicDataClipsMetadata.errorType = errorType;
  }
  final dynamic errorMessage = json['error_message'];
  if (errorMessage != null) {
    musicDataClipsMetadata.errorMessage = errorMessage;
  }
  return musicDataClipsMetadata;
}

Map<String, dynamic> $MusicDataClipsMetadataToJson(MusicDataClipsMetadata entity) {
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

extension MusicDataClipsMetadataExtension on MusicDataClipsMetadata {
  MusicDataClipsMetadata copyWith({
    String? tags,
    String? prompt,
    dynamic gptDescriptionPrompt,
    String? audioPromptId,
    List<MusicDataClipsMetadataHistory>? history,
    dynamic concatHistory,
    String? type,
    int? duration,
    bool? refundCredits,
    bool? stream,
    bool? infill,
    bool? hasVocal,
    bool? isAudioUploadTosAccepted,
    dynamic errorType,
    dynamic errorMessage,
  }) {
    return MusicDataClipsMetadata()
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

MusicDataClipsMetadataHistory $MusicDataClipsMetadataHistoryFromJson(Map<String, dynamic> json) {
  final MusicDataClipsMetadataHistory musicDataClipsMetadataHistory = MusicDataClipsMetadataHistory();
  final String? id = jsonConvert.convert<String>(json['id']);
  if (id != null) {
    musicDataClipsMetadataHistory.id = id;
  }
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    musicDataClipsMetadataHistory.type = type;
  }
  final bool? infill = jsonConvert.convert<bool>(json['infill']);
  if (infill != null) {
    musicDataClipsMetadataHistory.infill = infill;
  }
  final String? source = jsonConvert.convert<String>(json['source']);
  if (source != null) {
    musicDataClipsMetadataHistory.source = source;
  }
  final double? continueAt = jsonConvert.convert<double>(json['continue_at']);
  if (continueAt != null) {
    musicDataClipsMetadataHistory.continueAt = continueAt;
  }
  return musicDataClipsMetadataHistory;
}

Map<String, dynamic> $MusicDataClipsMetadataHistoryToJson(MusicDataClipsMetadataHistory entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['type'] = entity.type;
  data['infill'] = entity.infill;
  data['source'] = entity.source;
  data['continue_at'] = entity.continueAt;
  return data;
}

extension MusicDataClipsMetadataHistoryExtension on MusicDataClipsMetadataHistory {
  MusicDataClipsMetadataHistory copyWith({
    String? id,
    String? type,
    bool? infill,
    String? source,
    double? continueAt,
  }) {
    return MusicDataClipsMetadataHistory()
      ..id = id ?? this.id
      ..type = type ?? this.type
      ..infill = infill ?? this.infill
      ..source = source ?? this.source
      ..continueAt = continueAt ?? this.continueAt;
  }
}