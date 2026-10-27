import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/id_generator.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/usecases/clear_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_financial_summary.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_month_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/load_sample_data.dart';
import 'package:fluxo/features/transactions/domain/usecases/restore_transaction.dart';

part 'transactions_state.dart';

/// Estado compartilhado entre a Home (resumo e gráficos) e o Extrato.
///
/// As ações retornam `null` em caso de sucesso ou a mensagem de erro,
/// para que a UI decida como exibi-la (ex.: SnackBar).
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required GetMonthTransactions getMonthTransactions,
    required GetFinancialSummary getFinancialSummary,
    required DeleteTransaction deleteTransaction,
    required RestoreTransaction restoreTransaction,
    required LoadSampleData loadSampleData,
    required ClearTransactions clearTransactions,
    Clock clock = systemClock,
  }) : _getMonthTransactions = getMonthTransactions,
       _getFinancialSummary = getFinancialSummary,
       _deleteTransaction = deleteTransaction,
       _restoreTransaction = restoreTransaction,
       _loadSampleData = loadSampleData,
       _clearTransactions = clearTransactions,
       _clock = clock,
       super(TransactionsState.initial(clock()));

  final GetMonthTransactions _getMonthTransactions;
  final GetFinancialSummary _getFinancialSummary;
  final DeleteTransaction _deleteTransaction;
  final RestoreTransaction _restoreTransaction;
  final LoadSampleData _loadSampleData;
  final ClearTransactions _clearTransactions;
  final Clock _clock;

  /// Identifica a requisição mais recente para descartar respostas antigas
  /// (ex.: usuário troca de mês rapidamente).
  int _requestId = 0;

  /// Não permite navegar para meses futuros.
  bool get canGoToNextMonth =>
      state.month.isBefore(AppDateUtils.startOfMonth(_clock()));

  /// Carrega (ou recarrega) transações e resumo do mês selecionado.
  ///
  /// O indicador de carregamento só aparece na primeira carga; recargas
  /// mantêm os dados atuais na tela até a resposta chegar.
  Future<void> load() async {
    if (isClosed) return;
    final requestId = ++_requestId;
    final month = state.month;
    if (state.status != TransactionsStatus.success) {
      emit(state.copyWith(status: TransactionsStatus.loading, clearError: true));
    }

    final results = await (
      _getMonthTransactions(month),
      _getFinancialSummary(SummaryParams(month: month)),
    ).wait;

    if (isClosed || requestId != _requestId) return;

    switch (results) {
      case (Ok(value: final transactions), Ok(value: final summary)):
        emit(
          state.copyWith(
            status: TransactionsStatus.success,
            transactions: transactions,
            summary: summary,
            clearError: true,
          ),
        );
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(state.copyWith(status: TransactionsStatus.failure, errorMessage: failure.message));
    }
  }

  Future<void> changeMonth(DateTime month) async {
    final target = AppDateUtils.startOfMonth(month);
    if (target == state.month) return;
    emit(state.copyWith(month: target));
    await load();
  }

  Future<void> previousMonth() => changeMonth(AppDateUtils.addMonths(state.month, -1));

  Future<void> nextMonth() async {
    if (!canGoToNextMonth) return;
    await changeMonth(AppDateUtils.addMonths(state.month, 1));
  }

  Future<void> goToCurrentMonth() => changeMonth(_clock());

  void setFilter(TransactionFilter filter) {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
  }

  /// Remove a transação de forma otimista e recarrega o resumo.
  Future<String?> delete(TransactionEntity transaction) async {
    final previous = state.transactions;
    emit(
      state.copyWith(
        transactions: previous.where((t) => t.id != transaction.id).toList(growable: false),
      ),
    );

    final result = await _deleteTransaction(transaction.id);
    final error = result.failureOrNull?.message;
    if (error != null && !isClosed) {
      emit(state.copyWith(transactions: previous));
    }
    await load();
    return error;
  }

  /// Desfaz uma exclusão.
  Future<String?> restore(TransactionEntity transaction) async {
    final result = await _restoreTransaction(transaction);
    await load();
    return result.failureOrNull?.message;
  }

  Future<String?> loadSampleData() async {
    final result = await _loadSampleData(const NoParams());
    if (result.isOk && !isClosed) {
      // Volta ao mês atual para que os dados apareçam imediatamente.
      emit(state.copyWith(month: AppDateUtils.startOfMonth(_clock())));
    }
    await load();
    return result.failureOrNull?.message;
  }

  Future<String?> clearAll() async {
    final result = await _clearTransactions(const NoParams());
    await load();
    return result.failureOrNull?.message;
  }
}
