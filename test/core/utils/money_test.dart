import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/utils/money.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('Money.format', () {
    test('formata centavos em reais no padrão brasileiro', () {
      expect(normalizeSpaces(Money.format(123456)), r'R$ 1.234,56');
      expect(normalizeSpaces(Money.format(5)), r'R$ 0,05');
      expect(normalizeSpaces(Money.format(0)), r'R$ 0,00');
    });

    test('formatSigned adiciona o sinal explícito', () {
      expect(normalizeSpaces(Money.formatSigned(1000)), r'+R$ 10,00');
      expect(normalizeSpaces(Money.formatSigned(-1000)), r'-R$ 10,00');
      expect(normalizeSpaces(Money.formatSigned(0)), r'R$ 0,00');
    });
  });

  group('Money.parseCents', () {
    test('extrai apenas os dígitos como centavos', () {
      expect(Money.parseCents(r'R$ 1.234,56'), 123456);
      expect(Money.parseCents('12'), 12);
    });

    test('retorna zero quando não há dígitos', () {
      expect(Money.parseCents(''), 0);
      expect(Money.parseCents(r'R$ '), 0);
    });
  });

  test('toCents arredonda corretamente', () {
    expect(Money.toCents(12.5), 1250);
    expect(Money.toCents(0.1 + 0.2), 30);
  });
}
