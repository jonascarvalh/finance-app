part of 'transactions_cubit.dart';

enum TransactionsStatus { initial, loading, success, failure }

/// Filtro aplicado à lista do extrato.
enum TransactionFilter {
  all,
  income,
  expense;

  bool matches(TransactionEntity transaction) => switch (this) {
    TransactionFilter.all => true,
    TransactionFilter.income => transaction.isIncome,
    TransactionFilter.expense => transaction.isExpense,
  };
}

final class TransactionsState extends Equatable {
  const TransactionsState({
    required this.month,
    required this.summary,
    this.status = TransactionsStatus.initial,
    this.transactions = const [],
    this.filter = TransactionFilter.all,
    this.errorMessage,
  });

  factory TransactionsState.initial(DateTime month) {
    final start = AppDateUtils.startOfMonth(month);
    return TransactionsState(month: start, summary: FinancialSummary.empty(start));
  }

  final TransactionsStatus status;

  /// Mês selecionado (dia 1).
  final DateTime month;

  /// Transações do mês selecionado, das mais recentes para as mais antigas.
  final List<TransactionEntity> transactions;

  final FinancialSummary summary;
  final TransactionFilter filter;
  final String? errorMessage;

  bool get isLoading => status == TransactionsStatus.loading;

  bool get hasLoaded => status == TransactionsStatus.success;

  List<TransactionEntity> get filteredTransactions => filter == TransactionFilter.all
      ? transactions
      : transactions.where(filter.matches).toList(growable: false);

  TransactionsState copyWith({
    TransactionsStatus? status,
    DateTime? month,
    List<TransactionEntity>? transactions,
    FinancialSummary? summary,
    TransactionFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      month: month ?? this.month,
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, month, transactions, summary, filter, errorMessage];
}
