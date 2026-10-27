import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';

import '../../../helpers/fixtures.dart';

void main() {
  test('converte entidade → mapa → entidade sem perda', () {
    final entity = expense(note: 'Compra do mês');

    final map = TransactionModel.fromEntity(entity).toMap();
    final restored = TransactionModel.fromMap(map).toEntity();

    expect(restored, entity);
  });

  test('grava enums pelo nome e datas em milissegundos', () {
    final entity = income(date: DateTime(2026, 10, 5, 8, 30));

    final map = TransactionModel.fromEntity(entity).toMap();

    expect(map[TransactionFields.type], 'income');
    expect(map[TransactionFields.category], 'salary');
    expect(map[TransactionFields.date], DateTime(2026, 10, 5, 8, 30).millisecondsSinceEpoch);
    expect(map[TransactionFields.note], isNull);
  });

  test('toEntity falha com categoria desconhecida', () {
    final map = TransactionModel.fromEntity(expense()).toMap()
      ..[TransactionFields.category] = 'inexistente';

    expect(() => TransactionModel.fromMap(map).toEntity(), throwsArgumentError);
  });
}
