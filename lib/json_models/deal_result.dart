class DealResult {
  int width;
  int height;
  final bool pm;
  final String negativePrompt;
  final bool isReal;
  final bool addRandomPrompts;

  DealResult({
    this.width = 512,
    this.height = 512,
    required this.pm,
    required this.negativePrompt,
    required this.isReal,
    required this.addRandomPrompts,
  });
}