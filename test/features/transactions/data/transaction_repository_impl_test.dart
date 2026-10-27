import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';
import 'package:fluxo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockTransactionLocalDataSource local;
  late TransactionRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(TransactionModel.fromEntity(expense())));

  setUp(() {
    local = MockTransactionLocalDataSource();
    repository = TransactionRepositoryImpl(local);
  });

  test('getTransactions converte limites e modelos', () async {
    final entity = expense();
    when(
      () => local.getTransactions(
        startMillis: any(named: 'startMillis'),
        endMillis: any(named: 'endMillis'),
      ),
    ).thenAnswer((_) async => [TransactionModel.fromEntity(entity)]);

    final start = DateTime(2026, 10);
    final end = DateTime(2026, 11);
    final result = await repository.getTransactions(start: start, end: end);

    expect(result.valueOrNull, [entity]);
    verify(
      () => local.getTransactions(
        startMillis: start.millisecondsSinceEpoch,
        endMillis: end.millisecondsSinceEpoch,
      ),
    ).called(1);
  });

  test('converte LocalStorageException em StorageFailure', () async {
    when(() => local.insert(any())).thenThrow(const LocalStorageException('boom'));

    final result = await repository.addTransaction(expense());

    expect(result.failureOrNull, isA<StorageFailure>());
  });

  test('converte RecordNotFoundException em NotFoundFailure', () async {
    when(() => local.update(any())).thenThrow(const RecordNotFoundException('não existe'));

    final result = await repository.updateTransaction(expense());

    expect(result.failureOrNull, const NotFoundFailure('não existe'));
  });

  test('dados corrompidos viram StorageFailure', () async {
    final corrupted = TransactionModel.fromMap(
      TransactionModel.fromEntity(expense()).toMap()..['category'] = 'xyz',
    );
    when(
      () => local.getTransactions(
        startMillis: any(named: 'startMillis'),
        endMillis: any(named: 'endMillis'),
      ),
    ).thenAnswer((_) async => [corrupted]);

    final result = await repository.getTransactions();

    expect(result.failureOrNull, isA<StorageFailure>());
  });

  test('deleteTransaction delega ao data source', () async {
    when(() => local.delete('abc')).thenAnswer((_) async {});

    final result = await repository.deleteTransaction('abc');

    expect(result, const Ok(unit));
    verify(() => local.delete('abc')).called(1);
  });
}
