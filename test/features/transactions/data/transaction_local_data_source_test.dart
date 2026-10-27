import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_database.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fixtures.dart';

/// Testes de integração com um SQLite real em memória (via FFI).
void main() {
  late Database db;
  late TransactionLocalDataSourceImpl dataSource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await TransactionDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    dataSource = TransactionLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  TransactionModel model(TransactionEntity entity) => TransactionModel.fromEntity(entity);

  test('insere e lista do mais recente para o mais antigo', () async {
    await dataSource.insertAll([
      model(expense(id: 'a', date: DateTime(2026, 10, 1))),
      model(expense(id: 'b', date: DateTime(2026, 10, 20))),
      model(income(id: 'c', date: DateTime(2026, 10, 10))),
    ]);

    final all = await dataSource.getTransactions();

    expect(all.map((m) => m.id), ['b', 'c', 'a']);
  });

  test('filtra por intervalo [início, fim)', () async {
    await dataSource.insertAll([
      model(expense(id: 'set', date: DateTime(2026, 9, 30, 23, 59))),
      model(expense(id: 'out', date: DateTime(2026, 10, 15))),
      model(expense(id: 'nov', date: DateTime(2026, 11))),
    ]);

    final october = await dataSource.getTransactions(
      startMillis: DateTime(2026, 10).millisecondsSinceEpoch,
      endMillis: DateTime(2026, 11).millisecondsSinceEpoch,
    );

    expect(october.map((m) => m.id), ['out']);
  });

  test('calcula o saldo com sinal por tipo', () async {
    await dataSource.insertAll([
      model(income(id: 'a', cents: 100000, date: DateTime(2026, 9, 1))),
      model(expense(id: 'b', cents: 30000, date: DateTime(2026, 9, 2))),
      model(expense(id: 'c', cents: 5000, date: DateTime(2026, 10, 2))),
    ]);

    expect(await dataSource.getBalance(), 65000);
    expect(await dataSource.getBalance(beforeMillis: DateTime(2026, 10).millisecondsSinceEpoch), 70000);
  });

  test('saldo de banco vazio é zero', () async {
    expect(await dataSource.getBalance(), 0);
  });

  test('atualiza e exclui registros', () async {
    await dataSource.insert(model(expense(id: 'x', cents: 1000)));

    await dataSource.update(model(expense(id: 'x', cents: 2500, title: 'Novo')));
    final updated = (await dataSource.getTransactions()).single;
    expect(updated.amountInCents, 2500);
    expect(updated.title, 'Novo');

    await dataSource.delete('x');
    expect(await dataSource.getTransactions(), isEmpty);
  });

  test('atualizar registro inexistente lança RecordNotFoundException', () {
    expect(
      () => dataSource.update(model(expense(id: 'fantasma'))),
      throwsA(isA<RecordNotFoundException>()),
    );
  });

  test('deleteAll limpa a tabela', () async {
    await dataSource.insertAll([model(expense(id: 'a')), model(income(id: 'b'))]);

    await dataSource.deleteAll();

    expect(await dataSource.getTransactions(), isEmpty);
  });
}
