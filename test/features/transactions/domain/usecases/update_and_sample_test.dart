import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/usecases/load_sample_data.dart';
import 'package:fluxo/features/transactions/domain/usecases/update_transaction.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTransactionRepository repository;

  setUpAll(() {
    registerFallbackValue(expense());
    registerFallbackValue(<TransactionEntity>[]);
  });

  setUp(() => repository = MockTransactionRepository());

  group('UpdateTransaction', () {
    late UpdateTransaction useCase;

    setUp(() {
      useCase = UpdateTransaction(repository);
      when(() => repository.updateTransaction(any())).thenAnswer((_) async => const Ok(unit));
    });

    test('normaliza descrição e remove observação vazia', () async {
      final input = expense(title: '  Feira  ', note: '   ');

      final result = await useCase(input);

      final expected = expense(title: 'Feira');
      expect(result.valueOrNull, expected);
      verify(() => repository.updateTransaction(expected)).called(1);
    });

    test('não salva transação inválida', () async {
      final result = await useCase(expense(cents: 0));

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => repository.updateTransaction(any()));
    });
  });

  group('LoadSampleData', () {
    final now = DateTime(2026, 10, 27, 15);

    test('gera dados apenas até "agora", cobrindo 6 meses', () {
      final sample = LoadSampleData.buildSample(now: now, idGenerator: SequentialIdGenerator());

      expect(sample, isNotEmpty);
      expect(sample.every((t) => !t.date.isAfter(now)), isTrue);
      expect(sample.every((t) => t.category.type == t.type), isTrue);
      expect(sample.every((t) => t.amountInCents > 0), isTrue);

      final months = sample.map((t) => AppDateUtils.startOfMonth(t.date)).toSet();
      expect(months, hasLength(LoadSampleData.monthsOfData));
      expect(sample.map((t) => t.id).toSet(), hasLength(sample.length));
    });

    test('é determinístico', () {
      List<int> amounts() => LoadSampleData.buildSample(
        now: now,
        idGenerator: SequentialIdGenerator(),
      ).map((t) => t.amountInCents).toList();

      expect(amounts(), amounts());
    });

    test('persiste tudo de uma vez e retorna a quantidade', () async {
      when(() => repository.addTransactions(any())).thenAnswer((_) async => const Ok(unit));
      final useCase = LoadSampleData(repository, SequentialIdGenerator(), () => now);

      final result = await useCase(const NoParams());

      final saved = verify(() => repository.addTransactions(captureAny())).captured.single
          as List<TransactionEntity>;
      expect(result.valueOrNull, saved.length);
    });
  });
}
