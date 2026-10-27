import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/transaction_validator.dart';
import 'package:fluxo/features/transactions/domain/usecases/update_transaction.dart';

part 'transaction_form_state.dart';

/// Controla o formulário de criação/edição de uma transação.
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit({
    required AddTransaction addTransaction,
    required UpdateTransaction updateTransaction,
    required DeleteTransaction deleteTransaction,
    required TransactionFormState initialState,
  }) : _addTransaction = addTransaction,
       _updateTransaction = updateTransaction,
       _deleteTransaction = deleteTransaction,
       super(initialState);

  final AddTransaction _addTransaction;
  final UpdateTransaction _updateTransaction;
  final DeleteTransaction _deleteTransaction;

  void typeChanged(TransactionType type) {
    if (type == state.type) return;
    emit(state.copyWith(type: type, category: TransactionCategory.defaultFor(type)));
  }

  void categoryChanged(TransactionCategory category) =>
      emit(state.copyWith(category: category, type: category.type));

  void titleChanged(String value) => emit(state.copyWith(title: value));

  void amountChanged(int cents) => emit(state.copyWith(amountInCents: cents));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  Future<void> submit() async {
    if (state.isSubmitting) return;

    if (!state.isValid) {
      emit(state.copyWith(showErrors: true, status: FormStatus.editing, clearError: true));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    final original = state.original;
    final Result<TransactionEntity> result;
    if (original == null) {
      result = await _addTransaction(
        AddTransactionParams(
          title: state.title,
          amountInCents: state.amountInCents,
          type: state.type,
          category: state.category,
          date: state.date,
          note: state.note,
        ),
      );
    } else {
      final hasNote = state.note.trim().isNotEmpty;
      result = await _updateTransaction(
        original.copyWith(
          title: state.title,
          amountInCents: state.amountInCents,
          type: state.type,
          category: state.category,
          date: state.date,
          note: hasNote ? state.note : null,
          clearNote: !hasNote,
        ),
      );
    }

    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(status: FormStatus.saved));
      case Err(:final failure):
        emit(state.copyWith(status: FormStatus.failure, errorMessage: failure.message));
    }
  }

  Future<void> delete() async {
    final original = state.original;
    if (original == null || state.isSubmitting) return;

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _deleteTransaction(original.id);

    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(status: FormStatus.deleted));
      case Err(:final failure):
        emit(state.copyWith(status: FormStatus.failure, errorMessage: failure.message));
    }
  }
}
