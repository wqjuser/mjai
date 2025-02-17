class ItemModel {
  final String title;
  final String assetName;
  final int position;
  final double rotateAngle;

  ItemModel(this.title, this.assetName, this.position, {this.rotateAngle = 0});
}

class ImageItemModel {
  int position;
  String id;
  bool isMj;
  bool isSwapFace;
  bool isMJV6;
  bool isUpScaled;
  String base64Url;
  List<dynamic> buttons;
  int drawEngine;
  String seed;
  bool downloaded;
  String imageUrl;
  bool isSquare;
  bool isEnlarge;
  String prompt;
  bool isNijiV6;
  String? imageKey;
  bool isPublic;
  double? imageAspectRatio;
  String? drawProgress;

  ImageItemModel(this.position, this.id, this.isMj, this.isUpScaled, this.base64Url, this.buttons, this.drawEngine, this.seed, this.downloaded,
      this.imageUrl, this.isSwapFace, this.isMJV6,
      {this.isSquare = true,
        this.isEnlarge = false,
        this.isNijiV6 = false,
        this.prompt = '',
        this.imageKey = '',
        this.isPublic = false,
        this.imageAspectRatio,
        this.drawProgress = '0%'});

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'id': id,
      'isMj': isMj,
      'isSwapFace': isSwapFace,
      'isMJV6': isMJV6,
      'isUpScaled': isUpScaled,
      'base64Url': base64Url,
      'buttons': buttons,
      'drawEngine': drawEngine,
      'seed': seed,
      'downloaded': downloaded,
      'imageUrl': imageUrl,
      'isSquare': isSquare,
      'isEnlarge': isEnlarge,
      'prompt': prompt,
      'isNijiV6': isNijiV6,
      'imageKey': imageKey,
      'isPublic': isPublic,
      'imageAspectRatio': imageAspectRatio,
      'drawProgress': drawProgress
    };
  }

  factory ImageItemModel.fromJson(Map<String, dynamic> json) {
    return ImageItemModel(
      json['position'],
      json['id'],
      json['isMj'],
      json['isUpScaled'],
      json['base64Url'],
      json['buttons'],
      json['drawEngine'],
      json['seed'],
      json['downloaded'],
      json['imageUrl'],
      json['isSwapFace'],
      json['isMJV6'],
      isSquare: json['isSquare'],
      isEnlarge: json['isEnlarge'],
      prompt: json['prompt'],
      isNijiV6: json['isNijiV6'],
      imageKey: json['imageKey'],
      isPublic: json['isPublic'],
      imageAspectRatio: json['imageAspectRatio'],
      drawProgress: json['drawProgress'],
    );
  }
}

class MJItemModel {
  List<String> actions;

  MJItemModel(this.actions);
}