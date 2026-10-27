import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';

/// Contrato de acesso às transações. Implementado na camada de dados.
abstract interface class TransactionRepository {
  /// Transações com data em `[start, end)`, da mais recente para a mais antiga.
  /// Sem limites, retorna todas.
  Future<Result<List<TransactionEntity>>> getTransactions({DateTime? start, DateTime? end});

  /// Saldo (entradas − saídas) de todas as transações anteriores a [before].
  /// Sem limite, considera todas.
  Future<Result<int>> getBalance({DateTime? before});

  Future<Result<Unit>> addTransaction(TransactionEntity transaction);

  Future<Result<Unit>> addTransactions(List<TransactionEntity> transactions);

  Future<Result<Unit>> updateTransaction(TransactionEntity transaction);

  Future<Result<Unit>> deleteTransaction(String id);

  Future<Result<Unit>> deleteAll();
}
