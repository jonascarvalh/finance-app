import 'package:equatable/equatable.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Calcula o resumo financeiro de um mês: saldo acumulado, entradas,
/// saídas, histórico dos últimos meses e gastos por categoria.
class GetFinancialSummary implements UseCase<FinancialSummary, SummaryParams> {
  const GetFinancialSummary(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<FinancialSummary>> call(SummaryParams params) async {
    final month = AppDateUtils.startOfMonth(params.month);
    final rangeStart = AppDateUtils.addMonths(month, -(params.historyLength - 1));
    final rangeEnd = AppDateUtils.startOfNextMonth(month);

    final transactionsResult = await _repository.getTransactions(start: rangeStart, end: rangeEnd);
    final List<TransactionEntity> transactions;
    switch (transactionsResult) {
      case Ok(:final value):
        transactions = value;
      case Err(:final failure):
        return Err(failure);
    }

    final balanceResult = await _repository.getBalance(before: rangeEnd);
    final int balance;
    switch (balanceResult) {
      case Ok(:final value):
        balance = value;
      case Err(:final failure):
        return Err(failure);
    }

    final history = _buildHistory(transactions, rangeStart, params.historyLength);
    final current = history.last;

    return Ok(
      FinancialSummary(
        month: month,
        balanceInCents: balance,
        incomeInCents: current.incomeInCents,
        expenseInCents: current.expenseInCents,
        history: history,
        expensesByCategory: _groupExpensesByCategory(
          transactions.where((t) => AppDateUtils.isSameMonth(t.date, month)),
        ),
      ),
    );
  }

  List<MonthlyTotals> _buildHistory(
    List<TransactionEntity> transactions,
    DateTime firstMonth,
    int length,
  ) {
    return List<MonthlyTotals>.generate(length, (index) {
      final month = AppDateUtils.addMonths(firstMonth, index);
      var income = 0;
      var expense = 0;
      for (final t in transactions) {
        if (!AppDateUtils.isSameMonth(t.date, month)) continue;
        if (t.isIncome) {
          income += t.amountInCents;
        } else {
          expense += t.amountInCents;
        }
      }
      return MonthlyTotals(month: month, incomeInCents: income, expenseInCents: expense);
    }, growable: false);
  }

  List<CategoryTotal> _groupExpensesByCategory(Iterable<TransactionEntity> transactions) {
    final totals = <TransactionCategory, int>{};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      totals.update(t.category, (sum) => sum + t.amountInCents, ifAbsent: () => t.amountInCents);
    }

    final grandTotal = totals.values.fold<int>(0, (sum, value) => sum + value);
    if (grandTotal == 0) return const [];

    final result = [
      for (final entry in totals.entries)
        CategoryTotal(
          category: entry.key,
          amountInCents: entry.value,
          share: entry.value / grandTotal,
        ),
    ]..sort((a, b) => b.amountInCents.compareTo(a.amountInCents));

    return List.unmodifiable(result);
  }
}

class SummaryParams extends Equatable {
  const SummaryParams({required this.month, this.historyLength = 6})
    : assert(historyLength > 0, 'historyLength deve ser positivo');

  final DateTime month;

  /// Quantidade de meses no histórico (incluindo o mês de referência).
  final int historyLength;

  @override
  List<Object?> get props => [month, historyLength];
}
