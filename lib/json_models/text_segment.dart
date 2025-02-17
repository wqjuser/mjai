class TextSegment {
  final String content;
  final bool isPasted;
  final int position;
  final String? fileKey; // 如果是粘贴的文件，存储对应的key

  TextSegment({
    required this.content,
    required this.isPasted,
    required this.position,
    this.fileKey,
  });
}