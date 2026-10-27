import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_financial_summary.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockGetMonthTransactions getMonthTransactions;
  late MockGetFinancialSummary getFinancialSummary;
  late MockDeleteTransaction deleteTransaction;
  late MockRestoreTransaction restoreTransaction;
  late MockLoadSampleData loadSampleData;
  late MockClearTransactions clearTransactions;

  final now = DateTime(2026, 10, 27, 10);
  final october = DateTime(2026, 10);
  final september = DateTime(2026, 9);

  final salary = income(id: 'a', date: DateTime(2026, 10, 5));
  final market = expense(id: 'b', date: DateTime(2026, 10, 10));
  final summary = FinancialSummary.empty(october);

  setUpAll(() {
    registerFallbackValue(SummaryParams(month: october));
    registerFallbackValue(const NoParams());
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(expense());
  });

  setUp(() {
    getMonthTransactions = MockGetMonthTransactions();
    getFinancialSummary = MockGetFinancialSummary();
    deleteTransaction = MockDeleteTransaction();
    restoreTransaction = MockRestoreTransaction();
    loadSampleData = MockLoadSampleData();
    clearTransactions = MockClearTransactions();

    when(() => getMonthTransactions(any())).thenAnswer((_) async => Ok([market, salary]));
    when(() => getFinancialSummary(any())).thenAnswer((_) async => Ok(summary));
  });

  TransactionsCubit build() => TransactionsCubit(
    getMonthTransactions: getMonthTransactions,
    getFinancialSummary: getFinancialSummary,
    deleteTransaction: deleteTransaction,
    restoreTransaction: restoreTransaction,
    loadSampleData: loadSampleData,
    clearTransactions: clearTransactions,
    clock: () => now,
  );

  test('estado inicial aponta para o mês atual', () {
    final cubit = build();
    expect(cubit.state.month, october);
    expect(cubit.state.status, TransactionsStatus.initial);
    expect(cubit.canGoToNextMonth, isFalse);
  });

  blocTest<TransactionsCubit, TransactionsState>(
    'load emite carregando e depois sucesso',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<TransactionsState>().having((s) => s.status, 'status', TransactionsStatus.loading),
      isA<TransactionsState>()
          .having((s) => s.status, 'status', TransactionsStatus.success)
          .having((s) => s.transactions, 'transactions', [market, salary])
          .having((s) => s.summary, 'summary', summary),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'load emite falha com a mensagem do erro',
    setUp: () => when(() => getFinancialSummary(any()))
        .thenAnswer((_) async => Err(const StorageFailure('Falhou'))),
    build: build,
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => [
      isA<TransactionsState>()
          .having((s) => s.status, 'status', TransactionsStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'Falhou'),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'previousMonth troca o mês e recarrega',
    build: build,
    act: (cubit) => cubit.previousMonth(),
    verify: (cubit) {
      expect(cubit.state.month, september);
      expect(cubit.canGoToNextMonth, isTrue);
      verify(() => getMonthTransactions(september)).called(1);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'nextMonth não avança além do mês atual',
    build: build,
    act: (cubit) => cubit.nextMonth(),
    expect: () => <TransactionsState>[],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'setFilter filtra a lista sem nova consulta',
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.setFilter(TransactionFilter.income);
    },
    verify: (cubit) {
      expect(cubit.state.filteredTransactions, [salary]);
      verify(() => getMonthTransactions(any())).called(1);
    },
  );

  group('delete', () {
    blocTest<TransactionsCubit, TransactionsState>(
      'remove de forma otimista e recarrega',
      setUp: () => when(() => deleteTransaction(any())).thenAnswer((_) async => const Ok(unit)),
      build: build,
      seed: () => TransactionsState(
        month: october,
        summary: summary,
        status: TransactionsStatus.success,
        transactions: [market, salary],
      ),
      act: (cubit) async {
        when(() => getMonthTransactions(any())).thenAnswer((_) async => Ok([salary]));
        final error = await cubit.delete(market);
        expect(error, isNull);
      },
      expect: () => [
        isA<TransactionsState>().having((s) => s.transactions, 'transactions', [salary]),
      ],
      verify: (_) => verify(() => deleteTransaction(market.id)).called(1),
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'restaura a lista quando a exclusão falha',
      setUp: () => when(() => deleteTransaction(any()))
          .thenAnswer((_) async => Err(const StorageFailure('Erro'))),
      build: build,
      seed: () => TransactionsState(
        month: october,
        summary: summary,
        status: TransactionsStatus.success,
        transactions: [market, salary],
      ),
      act: (cubit) async {
        final error = await cubit.delete(market);
        expect(error, 'Erro');
      },
      verify: (cubit) => expect(cubit.state.transactions, [market, salary]),
    );
  });

  blocTest<TransactionsCubit, TransactionsState>(
    'restore reinsere a transação e recarrega',
    setUp: () => when(() => restoreTransaction(any())).thenAnswer((_) async => const Ok(unit)),
    build: build,
    act: (cubit) => cubit.restore(market),
    verify: (_) {
      verify(() => restoreTransaction(market)).called(1);
      verify(() => getMonthTransactions(any())).called(1);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'loadSampleData volta para o mês atual',
    setUp: () => when(() => loadSampleData(any())).thenAnswer((_) async => const Ok(42)),
    build: build,
    seed: () => TransactionsState(month: september, summary: FinancialSummary.empty(september)),
    act: (cubit) => cubit.loadSampleData(),
    verify: (cubit) => expect(cubit.state.month, october),
  );
}
