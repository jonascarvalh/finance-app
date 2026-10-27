import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_financial_summary.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTransactionRepository repository;
  late GetFinancialSummary useCase;

  final october = DateTime(2026, 10);

  setUp(() {
    repository = MockTransactionRepository();
    useCase = GetFinancialSummary(repository);
  });

  void stubRepository(List<TransactionEntity> transactions, {int balance = 0}) {
    when(
      () => repository.getTransactions(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => Ok(transactions));
    when(
      () => repository.getBalance(before: any(named: 'before')),
    ).thenAnswer((_) async => Ok(balance));
  }

  test('consulta o intervalo do histórico e o saldo até o fim do mês', () async {
    stubRepository([]);

    await useCase(SummaryParams(month: DateTime(2026, 10, 15), historyLength: 3));

    verify(
      () => repository.getTransactions(start: DateTime(2026, 8), end: DateTime(2026, 11)),
    ).called(1);
    verify(() => repository.getBalance(before: DateTime(2026, 11))).called(1);
  });

  test('calcula totais do mês, histórico e gastos por categoria', () async {
    stubRepository([
      income(id: 'a', cents: 500000, date: DateTime(2026, 10, 5)),
      expense(id: 'b', cents: 30000, date: DateTime(2026, 10, 7)),
      expense(id: 'c', cents: 10000, date: DateTime(2026, 10, 9), category: TransactionCategory.transport),
      expense(id: 'd', cents: 60000, date: DateTime(2026, 10, 12), category: TransactionCategory.housing),
      // Mês anterior: entra no histórico, mas não no mês de referência.
      income(id: 'e', cents: 200000, date: DateTime(2026, 9, 5)),
      expense(id: 'f', cents: 50000, date: DateTime(2026, 9, 20)),
    ], balance: 610000);

    final result = await useCase(SummaryParams(month: october, historyLength: 3));
    final summary = result.valueOrNull!;

    expect(summary.month, october);
    expect(summary.balanceInCents, 610000);
    expect(summary.incomeInCents, 500000);
    expect(summary.expenseInCents, 100000);
    expect(summary.monthBalanceInCents, 400000);

    expect(summary.history, [
      MonthlyTotals(month: DateTime(2026, 8), incomeInCents: 0, expenseInCents: 0),
      MonthlyTotals(month: DateTime(2026, 9), incomeInCents: 200000, expenseInCents: 50000),
      MonthlyTotals(month: october, incomeInCents: 500000, expenseInCents: 100000),
    ]);

    expect(summary.expensesByCategory.map((c) => c.category), [
      TransactionCategory.housing,
      TransactionCategory.food,
      TransactionCategory.transport,
    ]);
    expect(summary.expensesByCategory.first.share, closeTo(0.6, 1e-9));
    expect(
      summary.expensesByCategory.fold<double>(0, (sum, c) => sum + c.share),
      closeTo(1, 1e-9),
    );
  });

  test('sem saídas, a lista de categorias fica vazia', () async {
    stubRepository([income(date: DateTime(2026, 10, 5))]);

    final summary = (await useCase(SummaryParams(month: october))).valueOrNull!;

    expect(summary.expensesByCategory, isEmpty);
    expect(summary.history, hasLength(6));
  });

  test('propaga falha do repositório', () async {
    when(
      () => repository.getTransactions(start: any(named: 'start'), end: any(named: 'end')),
    ).thenAnswer((_) async => const Err(StorageFailure()));

    final result = await useCase(SummaryParams(month: october));

    expect(result.failureOrNull, isA<StorageFailure>());
    verifyNever(() => repository.getBalance(before: any(named: 'before')));
  });
}
