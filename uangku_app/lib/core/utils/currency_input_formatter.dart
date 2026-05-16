import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) != 0) {
      int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
      
      // Keep only digits
      String newString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (newString.isEmpty) {
         return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }
      
      int num = int.parse(newString);
      // Format with commas, then replace commas with dots
      final f = NumberFormat("#,###", "en_US"); 
      final newText = f.format(num).replaceAll(',', '.');

      int newSelection = newText.length - selectionIndexFromTheRight;
      if (newSelection < 0) {
        newSelection = 0;
      }
      
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newSelection),
      );
    } else {
      return newValue;
    }
  }
}
