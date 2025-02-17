import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isShow;
  final int? maxLines;

  const MyTextField(
      {Key? key,
      this.hintText = '',
      this.decoration = const InputDecoration(),
      this.onChanged,
      this.controller,
      this.style,
      this.keyboardType,
      this.isShow = false,
      this.maxLines=1,
      this.inputFormatters})
      : super(key: key);

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool _passwordVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = widget.isShow;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: TextField(
        style: widget.style,
        onChanged: widget.onChanged,
        controller: widget.controller,
        obscureText: !_passwordVisible,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        decoration: widget.decoration.copyWith(
          suffixIcon: Visibility(
            visible: _isHovered || _passwordVisible,
            child: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
