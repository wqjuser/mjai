import 'package:tuitu/generated/json/base/json_field.dart';
import 'package:tuitu/generated/json/music_response_entity.g.dart';
import 'dart:convert';
export 'package:tuitu/generated/json/music_response_entity.g.dart';

@JsonSerializable()
class MusicResponseEntity {
	String? id;
	List<MusicResponseClips>? clips;
	MusicResponseMetadata? metadata;
	@JSONField(name: "major_model_version")
	String? majorModelVersion;
	String? status;
	@JSONField(name: "created_at")
	String? createdAt;
	@JSONField(name: "batch_size")
	int? batchSize;

	MusicResponseEntity();

	factory MusicResponseEntity.fromJson(Map<String, dynamic> json) => $MusicResponseEntityFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicResponseClips {
	String? id;
	@JSONField(name: "video_url")
	String? videoUrl;
	@JSONField(name: "audio_url")
	String? audioUrl;
	@JSONField(name: "image_url")
	dynamic imageUrl;
	@JSONField(name: "image_large_url")
	dynamic imageLargeUrl;
	@JSONField(name: "is_video_pending")
	bool? isVideoPending;
	@JSONField(name: "major_model_version")
	String? majorModelVersion;
	@JSONField(name: "model_name")
	String? modelName;
	MusicResponseClipsMetadata? metadata;
	@JSONField(name: "is_liked")
	bool? isLiked;
	@JSONField(name: "user_id")
	String? userId;
	@JSONField(name: "display_name")
	String? displayName;
	String? handle;
	@JSONField(name: "is_handle_updated")
	bool? isHandleUpdated;
	@JSONField(name: "avatar_image_url")
	String? avatarImageUrl;
	@JSONField(name: "is_trashed")
	bool? isTrashed;
	dynamic reaction;
	@JSONField(name: "created_at")
	String? createdAt;
	String? status;
	String? title;
	@JSONField(name: "play_count")
	int? playCount;
	@JSONField(name: "upvote_count")
	int? upvoteCount;
	@JSONField(name: "is_public")
	bool? isPublic;

	MusicResponseClips();

	factory MusicResponseClips.fromJson(Map<String, dynamic> json) => $MusicResponseClipsFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseClipsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicResponseClipsMetadata {
	String? tags;
	String? prompt;
	@JSONField(name: "gpt_description_prompt")
	dynamic gptDescriptionPrompt;
	@JSONField(name: "audio_prompt_id")
	String? audioPromptId;
	List<MusicResponseClipsMetadataHistory>? history;
	@JSONField(name: "concat_history")
	dynamic concatHistory;
	String? type;
	dynamic duration;
	@JSONField(name: "refund_credits")
	dynamic refundCredits;
	bool? stream;
	bool? infill;
	@JSONField(name: "has_vocal")
	bool? hasVocal;
	@JSONField(name: "is_audio_upload_tos_accepted")
	bool? isAudioUploadTosAccepted;
	@JSONField(name: "error_type")
	dynamic errorType;
	@JSONField(name: "error_message")
	dynamic errorMessage;

	MusicResponseClipsMetadata();

	factory MusicResponseClipsMetadata.fromJson(Map<String, dynamic> json) => $MusicResponseClipsMetadataFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseClipsMetadataToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicResponseClipsMetadataHistory {
	String? id;
	@JSONField(name: "continue_at")
	double? continueAt;
	String? type;
	String? source;
	bool? infill;

	MusicResponseClipsMetadataHistory();

	factory MusicResponseClipsMetadataHistory.fromJson(Map<String, dynamic> json) => $MusicResponseClipsMetadataHistoryFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseClipsMetadataHistoryToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicResponseMetadata {
	String? tags;
	String? prompt;
	@JSONField(name: "gpt_description_prompt")
	dynamic gptDescriptionPrompt;
	@JSONField(name: "audio_prompt_id")
	String? audioPromptId;
	List<MusicResponseMetadataHistory>? history;
	@JSONField(name: "concat_history")
	dynamic concatHistory;
	String? type;
	dynamic duration;
	@JSONField(name: "refund_credits")
	dynamic refundCredits;
	bool? stream;
	bool? infill;
	@JSONField(name: "has_vocal")
	bool? hasVocal;
	@JSONField(name: "is_audio_upload_tos_accepted")
	bool? isAudioUploadTosAccepted;
	@JSONField(name: "error_type")
	dynamic errorType;
	@JSONField(name: "error_message")
	dynamic errorMessage;

	MusicResponseMetadata();

	factory MusicResponseMetadata.fromJson(Map<String, dynamic> json) => $MusicResponseMetadataFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseMetadataToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicResponseMetadataHistory {
	String? id;
	@JSONField(name: "continue_at")
	double? continueAt;
	String? type;
	String? source;
	bool? infill;

	MusicResponseMetadataHistory();

	factory MusicResponseMetadataHistory.fromJson(Map<String, dynamic> json) => $MusicResponseMetadataHistoryFromJson(json);

	Map<String, dynamic> toJson() => $MusicResponseMetadataHistoryToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}