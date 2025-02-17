import 'package:tuitu/generated/json/base/json_field.dart';
import 'package:tuitu/generated/json/music_data_entity.g.dart';
import 'dart:convert';
export 'package:tuitu/generated/json/music_data_entity.g.dart';

@JsonSerializable()
class MusicDataEntity {
	List<MusicDataClips>? clips;
	@JSONField(name: "num_total_results")
	int? numTotalResults;
	@JSONField(name: "current_page")
	int? currentPage;

	MusicDataEntity();

	factory MusicDataEntity.fromJson(Map<String, dynamic> json) => $MusicDataEntityFromJson(json);

	Map<String, dynamic> toJson() => $MusicDataEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicDataClips {
	String? id;
	@JSONField(name: "video_url")
	String? videoUrl;
	@JSONField(name: "audio_url")
	String? audioUrl;
	@JSONField(name: "image_url")
	String? imageUrl;
	@JSONField(name: "image_large_url")
	String? imageLargeUrl;
	@JSONField(name: "is_video_pending")
	bool? isVideoPending;
	@JSONField(name: "major_model_version")
	String? majorModelVersion;
	@JSONField(name: "model_name")
	String? modelName;
	MusicDataClipsMetadata? metadata;
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

	MusicDataClips();

	factory MusicDataClips.fromJson(Map<String, dynamic> json) => $MusicDataClipsFromJson(json);

	Map<String, dynamic> toJson() => $MusicDataClipsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicDataClipsMetadata {
	String? tags;
	String? prompt;
	@JSONField(name: "gpt_description_prompt")
	dynamic gptDescriptionPrompt;
	@JSONField(name: "audio_prompt_id")
	String? audioPromptId;
	List<MusicDataClipsMetadataHistory>? history;
	@JSONField(name: "concat_history")
	dynamic concatHistory;
	String? type;
	int? duration;
	@JSONField(name: "refund_credits")
	bool? refundCredits;
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

	MusicDataClipsMetadata();

	factory MusicDataClipsMetadata.fromJson(Map<String, dynamic> json) => $MusicDataClipsMetadataFromJson(json);

	Map<String, dynamic> toJson() => $MusicDataClipsMetadataToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class MusicDataClipsMetadataHistory {
	String? id;
	String? type;
	bool? infill;
	String? source;
	@JSONField(name: "continue_at")
	double? continueAt;

	MusicDataClipsMetadataHistory();

	factory MusicDataClipsMetadataHistory.fromJson(Map<String, dynamic> json) => $MusicDataClipsMetadataHistoryFromJson(json);

	Map<String, dynamic> toJson() => $MusicDataClipsMetadataHistoryToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}