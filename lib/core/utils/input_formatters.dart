import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// Fungsi yang bisa dipanggil di page lain
List<TextInputFormatter> getUpperCaseFormatter() {
  return [UpperCaseTextFormatter()];
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

// Fungsi yang bisa dipanggil di page lain
List<TextInputFormatter> getLowerCaseFormatter() {
  return [LowerCaseTextFormatter()];
}

String formatRupiah(String nominal) {
  double? numberDouble = double.tryParse(nominal.replaceAll(',', '.'));
  if (numberDouble == null) return '0';

  int number = numberDouble.toInt();

  String result = number.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return result;
}
