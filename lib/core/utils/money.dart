import 'package:intl/intl.dart';

/// Utilitários para valores monetários.
///
/// Todos os valores são armazenados em **centavos** (`int`) para evitar
/// erros de arredondamento de ponto flutuante.
abstract final class Money {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  static final NumberFormat _compact = NumberFormat.compact(locale: 'pt_BR');

  /// `123456` → `R$ 1.234,56`
  static String format(int cents) => _currency.format(cents / 100);

  /// Valor com sinal explícito: `+R$ 10,00` / `-R$ 10,00`.
  static String formatSigned(int cents) {
    final formatted = format(cents.abs());
    if (cents == 0) return formatted;
    return cents > 0 ? '+$formatted' : '-$formatted';
  }

  /// Número abreviado, sem símbolo, para eixos de gráfico:
  /// `1500000` (centavos) → `15 mil`.
  static String formatCompact(int cents) => _compact.format(cents / 100);

  /// Converte reais em centavos: `12.5` → `1250`.
  static int toCents(num value) => (value * 100).round();

  /// Extrai apenas os dígitos de um texto e os interpreta como centavos.
  ///
  /// `"R$ 1.234,56"` → `123456`. Retorna `0` se não houver dígitos.
  static int parseCents(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    // Limita o tamanho para evitar overflow em entradas absurdas.
    final safe = digits.length > 15 ? digits.substring(digits.length - 15) : digits;
    return int.parse(safe);
  }
}
