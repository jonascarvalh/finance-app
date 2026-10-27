import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Apaga todas as transações do dispositivo.
class ClearTransactions implements UseCase<Unit, NoParams> {
  const ClearTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<Unit>> call(NoParams params) => _repository.deleteAll();
}
