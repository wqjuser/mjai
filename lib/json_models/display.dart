class Display {
  final int id;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isPrimary;

  Display({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isPrimary,
  });

  factory Display.fromMap(Map<dynamic, dynamic> map) {
    return Display(
      id: map['id'] as int,
      x: map['x'] as double,
      y: map['y'] as double,
      width: map['width'] as double,
      height: map['height'] as double,
      isPrimary: map['isPrimary'] as bool,
    );
  }
}