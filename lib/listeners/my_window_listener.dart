import 'dart:ui';
import 'package:window_manager/window_manager.dart';

class MyWindowListener with WindowListener {
  final VoidCallback? onMyWindowClose;
  final VoidCallback? onMyWindowFocus;
  final VoidCallback? onMyWindowBlur;
  final VoidCallback? onMyWindowMaximize;
  final VoidCallback? onMyWindowUnmaximize;
  final VoidCallback? onMyWindowResize;

  MyWindowListener({
    this.onMyWindowClose,
    this.onMyWindowFocus,
    this.onMyWindowBlur,
    this.onMyWindowMaximize,
    this.onMyWindowUnmaximize,
    this.onMyWindowResize,
  });


  @override
  void onWindowClose() {
    onMyWindowClose?.call();
    super.onWindowClose();
  }

  @override
  void onWindowFocus() {
    onMyWindowFocus?.call();
    super.onWindowFocus();
  }

  @override
  void onWindowBlur() {
    onMyWindowBlur?.call();
    super.onWindowBlur();
  }

  @override
  void onWindowUnmaximize() {
    onMyWindowUnmaximize?.call();
    super.onWindowUnmaximize();
  }

  @override
  void onWindowMaximize() {
    onMyWindowMaximize?.call();
    super.onWindowMaximize();
  }

  @override
  void onWindowResize() {
    onMyWindowResize?.call();
    super.onWindowResize();
  }
}
