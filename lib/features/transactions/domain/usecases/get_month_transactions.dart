import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Lista as transações do mês informado, das mais recentes para as mais antigas.
class GetMonthTransactions implements UseCase<List<TransactionEntity>, DateTime> {
  const GetMonthTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<List<TransactionEntity>>> call(DateTime params) {
    return _repository.getTransactions(
      start: AppDateUtils.startOfMonth(params),
      end: AppDateUtils.startOfNextMonth(params),
    );
  }
}
