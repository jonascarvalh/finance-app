import 'package:intl/intl.dart';

/// Funções puras para manipulação de datas por mês/dia.
abstract final class AppDateUtils {
  /// Primeiro instante do mês de [date].
  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

  /// Primeiro instante do mês seguinte ao de [date] (limite exclusivo).
  static DateTime startOfNextMonth(DateTime date) => DateTime(date.year, date.month + 1);

  /// Soma (ou subtrai) [months] meses, sempre retornando o dia 1.
  static DateTime addMonths(DateTime date, int months) =>
      DateTime(date.year, date.month + months);

  static bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  /// `outubro de 2026`
  static String monthYear(DateTime date) => DateFormat("MMMM 'de' y", 'pt_BR').format(date);

  /// `out`
  static String shortMonth(DateTime date) =>
      DateFormat.MMM('pt_BR').format(date).replaceAll('.', '');

  /// `27 de out.` / `27/10/2026`
  static String dayMonth(DateTime date) => DateFormat("d 'de' MMM", 'pt_BR').format(date);

  static String fullDate(DateTime date) => DateFormat('dd/MM/yyyy', 'pt_BR').format(date);

  /// Rótulo amigável para cabeçalhos de lista: "Hoje", "Ontem" ou a data.
  static String relativeDayLabel(DateTime date, {required DateTime now}) {
    // Comparação em UTC evita distorções de horário de verão.
    final day = DateTime.utc(date.year, date.month, date.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Ontem';
    final weekday = DateFormat.EEEE('pt_BR').format(date);
    return '${_capitalize(weekday)}, ${dayMonth(date)}';
  }

  static String capitalize(String value) => _capitalize(value);

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
