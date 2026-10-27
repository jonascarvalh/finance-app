import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTransactionRepository repository;
  late AddTransaction useCase;

  final date = DateTime(2026, 10, 27, 10);

  AddTransactionParams params({
    String title = '  Supermercado  ',
    int cents = 15990,
    TransactionType type = TransactionType.expense,
    TransactionCategory category = TransactionCategory.food,
    String? note = '  ',
  }) {
    return AddTransactionParams(
      title: title,
      amountInCents: cents,
      type: type,
      category: category,
      date: date,
      note: note,
    );
  }

  setUpAll(() => registerFallbackValue(expense()));

  setUp(() {
    repository = MockTransactionRepository();
    useCase = AddTransaction(repository, SequentialIdGenerator());
    when(() => repository.addTransaction(any())).thenAnswer((_) async => const Ok(unit));
  });

  test('gera id, normaliza campos e salva no repositório', () async {
    final result = await useCase(params());

    final expected = TransactionEntity(
      id: 'id-1',
      title: 'Supermercado',
      amountInCents: 15990,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: date,
    );
    expect(result.valueOrNull, expected);
    verify(() => repository.addTransaction(expected)).called(1);
  });

  group('validação', () {
    test('rejeita descrição vazia', () async {
      final result = await useCase(params(title: '   '));
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejeita valor zero ou negativo', () async {
      expect((await useCase(params(cents: 0))).isErr, isTrue);
      expect((await useCase(params(cents: -10))).isErr, isTrue);
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejeita categoria incompatível com o tipo', () async {
      final result = await useCase(
        params(type: TransactionType.income, category: TransactionCategory.food),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  test('propaga falha do repositório', () async {
    when(() => repository.addTransaction(any()))
        .thenAnswer((_) async => const Err(StorageFailure()));

    final result = await useCase(params());

    expect(result.failureOrNull, const StorageFailure());
  });
}
