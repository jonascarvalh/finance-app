import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Remove uma transação pelo seu identificador.
class DeleteTransaction implements UseCase<Unit, String> {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  /// [params] é o id da transação.
  @override
  Future<Result<Unit>> call(String params) => _repository.deleteTransaction(params);
}
