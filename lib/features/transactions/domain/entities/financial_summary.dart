import 'package:equatable/equatable.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';

/// Totais de entradas e saídas de um mês.
class MonthlyTotals extends Equatable {
  const MonthlyTotals({
    required this.month,
    required this.incomeInCents,
    required this.expenseInCents,
  });

  /// Sempre o dia 1 do mês.
  final DateTime month;
  final int incomeInCents;
  final int expenseInCents;

  int get balanceInCents => incomeInCents - expenseInCents;

  @override
  List<Object?> get props => [month, incomeInCents, expenseInCents];
}

/// Total gasto em uma categoria e sua participação no total do mês.
class CategoryTotal extends Equatable {
  const CategoryTotal({
    required this.category,
    required this.amountInCents,
    required this.share,
  });

  final TransactionCategory category;
  final int amountInCents;

  /// Fração entre 0 e 1.
  final double share;

  @override
  List<Object?> get props => [category, amountInCents, share];
}

/// Visão consolidada exibida na Home.
class FinancialSummary extends Equatable {
  const FinancialSummary({
    required this.month,
    required this.balanceInCents,
    required this.incomeInCents,
    required this.expenseInCents,
    required this.history,
    required this.expensesByCategory,
  });

  /// Resumo vazio para o mês informado (usado antes do primeiro carregamento).
  FinancialSummary.empty(DateTime month)
    : this(
        month: DateTime(month.year, month.month),
        balanceInCents: 0,
        incomeInCents: 0,
        expenseInCents: 0,
        history: const [],
        expensesByCategory: const [],
      );

  /// Mês de referência (dia 1).
  final DateTime month;

  /// Saldo acumulado de todas as transações até o fim do mês de referência.
  final int balanceInCents;

  /// Entradas do mês de referência.
  final int incomeInCents;

  /// Saídas do mês de referência.
  final int expenseInCents;

  /// Totais mensais em ordem cronológica, terminando no mês de referência.
  final List<MonthlyTotals> history;

  /// Saídas do mês agrupadas por categoria, da maior para a menor.
  final List<CategoryTotal> expensesByCategory;

  int get monthBalanceInCents => incomeInCents - expenseInCents;

  bool get hasHistory => history.any((m) => m.incomeInCents > 0 || m.expenseInCents > 0);

  @override
  List<Object?> get props => [
    month,
    balanceInCents,
    incomeInCents,
    expenseInCents,
    history,
    expensesByCategory,
  ];
}
