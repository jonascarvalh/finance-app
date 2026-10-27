import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/presentation/formatters/currency_input_formatter.dart';

import '../../helpers/fixtures.dart';

void main() {
  const formatter = CurrencyInputFormatter(maxDigits: 6);

  TextEditingValue type(String oldText, String newText) => formatter.formatEditUpdate(
    TextEditingValue(text: oldText),
    TextEditingValue(text: newText),
  );

  test('dígitos entram pela direita como centavos', () {
    expect(normalizeSpaces(type('', '1').text), r'R$ 0,01');
    expect(normalizeSpaces(type(r'R$ 0,01', r'R$ 0,015').text), r'R$ 0,15');
    expect(normalizeSpaces(type(r'R$ 0,15', r'R$ 0,150').text), r'R$ 1,50');
  });

  test('apagar remove o último dígito', () {
    expect(normalizeSpaces(type(r'R$ 1,50', r'R$ 1,5').text), r'R$ 0,15');
  });

  test('valor zero limpa o campo', () {
    expect(type(r'R$ 0,01', r'R$ 0,0').text, isEmpty);
  });

  test('ignora dígitos além do limite', () {
    final old = TextEditingValue(text: type('', '123456').text);
    final result = formatter.formatEditUpdate(old, TextEditingValue(text: '${old.text}7'));
    expect(result, old);
  });

  test('mantém o cursor no final', () {
    final result = type('', '1234');
    expect(result.selection.baseOffset, result.text.length);
  });
}
