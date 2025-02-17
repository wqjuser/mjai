class VideoListData {
  String videoId;
  String prompt;
  String state;
  String createAt;
  bool isSelf;
  String severId;
  Map<String, dynamic>? video;

  VideoListData(this.videoId, {this.prompt = '', this.state = '', this.createAt = '', this.severId = '', this.isSelf = true, this.video});
}
