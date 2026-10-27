import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('addMonths atravessa a virada do ano', () {
    expect(AppDateUtils.addMonths(DateTime(2026, 11, 20), 3), DateTime(2027, 2));
    expect(AppDateUtils.addMonths(DateTime(2026, 2, 15), -3), DateTime(2025, 11));
  });

  test('startOfNextMonth retorna o limite exclusivo do mês', () {
    expect(AppDateUtils.startOfNextMonth(DateTime(2026, 12, 31)), DateTime(2027));
  });

  test('isSameMonth compara ano e mês', () {
    expect(AppDateUtils.isSameMonth(DateTime(2026, 10, 1), DateTime(2026, 10, 31, 23)), isTrue);
    expect(AppDateUtils.isSameMonth(DateTime(2026, 10), DateTime(2025, 10)), isFalse);
  });

  group('relativeDayLabel', () {
    final now = DateTime(2026, 10, 27, 9);

    test('usa "Hoje" e "Ontem"', () {
      expect(AppDateUtils.relativeDayLabel(DateTime(2026, 10, 27, 23), now: now), 'Hoje');
      expect(AppDateUtils.relativeDayLabel(DateTime(2026, 10, 26), now: now), 'Ontem');
    });

    test('usa dia da semana e data para dias anteriores', () {
      final label = AppDateUtils.relativeDayLabel(DateTime(2026, 10, 20), now: now);
      expect(label, startsWith('Terça-feira'));
      expect(label, contains('20 de out'));
    });
  });

  test('monthYear escreve o mês por extenso em português', () {
    expect(AppDateUtils.monthYear(DateTime(2026, 10)), 'outubro de 2026');
  });
}
