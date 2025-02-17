import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  final double minValue;
  final double maxValue;

  DecimalTextInputFormatter({required this.decimalRange, required this.minValue, required this.maxValue});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '0.00');
    } else {
      double value = double.tryParse(newValue.text) ?? 0.0;
      if (value < minValue || value > maxValue) {
        return oldValue;
      }

      String newText = newValue.text;
      if (newText.contains('.')) {
        List<String> parts = newText.split('.');
        String decimalPart = parts.length > 1 ? parts[1] : '';
        if (decimalPart.length > decimalRange) {
          decimalPart = decimalPart.substring(0, decimalRange);
        }
        newText = '${parts[0]}.${decimalPart.padRight(decimalRange, '0')}';
      } else {
        newText = newText.replaceAll(RegExp(r'[^0-9]'), '');
      }

      return newValue.copyWith(text: newText);
    }
  }
}

class RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  RangeTextInputFormatter({this.min = 64, this.max = 2048});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    int value = int.parse(newValue.text);
    if (value > max) {
      return TextEditingValue(text: max.toString());
    } else if (value < min) {
      return TextEditingValue(text: min.toString());
    } else {
      return newValue;
    }
  }
}
