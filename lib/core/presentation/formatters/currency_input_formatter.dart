import 'package:flutter/services.dart';
import 'package:fluxo/core/utils/money.dart';

/// Máscara de moeda estilo "caixa eletrônico": os dígitos digitados entram
/// pela direita como centavos (`1` → `R$ 0,01`, `150` → `R$ 1,50`).
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter({this.maxDigits = 12});

  /// Limite de dígitos aceitos (12 dígitos = até R$ 9.999.999.999,99).
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;

    final cents = digits.isEmpty ? 0 : int.parse(digits);
    if (cents == 0) return TextEditingValue.empty;

    final text = Money.format(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
