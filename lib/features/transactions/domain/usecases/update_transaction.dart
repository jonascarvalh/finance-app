import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fluxo/features/transactions/domain/usecases/transaction_validator.dart';

/// Atualiza uma transação existente.
class UpdateTransaction implements UseCase<TransactionEntity, TransactionEntity> {
  const UpdateTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<TransactionEntity>> call(TransactionEntity params) async {
    final note = params.note?.trim();
    final validationFailure = TransactionValidator.validate(
      title: params.title,
      amountInCents: params.amountInCents,
      type: params.type,
      category: params.category,
      note: note,
    );
    if (validationFailure != null) return Err(validationFailure);

    final sanitized = params.copyWith(
      title: params.title.trim(),
      note: note,
      clearNote: note == null || note.isEmpty,
    );

    final result = await _repository.updateTransaction(sanitized);
    return switch (result) {
      Ok() => Ok(sanitized),
      Err(:final failure) => Err(failure),
    };
  }
}
