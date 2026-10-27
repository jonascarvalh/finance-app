import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Reinsere uma transação recém-excluída (ação "Desfazer").
class RestoreTransaction implements UseCase<Unit, TransactionEntity> {
  const RestoreTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<Unit>> call(TransactionEntity params) => _repository.addTransaction(params);
}
