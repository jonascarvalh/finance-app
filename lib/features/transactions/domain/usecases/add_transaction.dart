import 'package:equatable/equatable.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/id_generator.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fluxo/features/transactions/domain/usecases/transaction_validator.dart';

/// Registra uma nova entrada ou saída.
class AddTransaction implements UseCase<TransactionEntity, AddTransactionParams> {
  const AddTransaction(this._repository, this._idGenerator);

  final TransactionRepository _repository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<TransactionEntity>> call(AddTransactionParams params) async {
    final note = params.note?.trim();
    final validationFailure = TransactionValidator.validate(
      title: params.title,
      amountInCents: params.amountInCents,
      type: params.type,
      category: params.category,
      note: note,
    );
    if (validationFailure != null) return Err(validationFailure);

    final transaction = TransactionEntity(
      id: _idGenerator.generate(),
      title: params.title.trim(),
      amountInCents: params.amountInCents,
      type: params.type,
      category: params.category,
      date: params.date,
      note: (note == null || note.isEmpty) ? null : note,
    );

    final result = await _repository.addTransaction(transaction);
    return switch (result) {
      Ok() => Ok(transaction),
      Err(:final failure) => Err(failure),
    };
  }
}

class AddTransactionParams extends Equatable {
  const AddTransactionParams({
    required this.title,
    required this.amountInCents,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  final String title;
  final int amountInCents;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;

  @override
  List<Object?> get props => [title, amountInCents, type, category, date, note];
}
