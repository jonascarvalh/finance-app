import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Implementação do repositório: delega ao data source e traduz
/// exceções em [Failure]s.
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._local);

  final TransactionLocalDataSource _local;

  @override
  Future<Result<List<TransactionEntity>>> getTransactions({DateTime? start, DateTime? end}) {
    return _run(() async {
      final models = await _local.getTransactions(
        startMillis: start?.millisecondsSinceEpoch,
        endMillis: end?.millisecondsSinceEpoch,
      );
      return models.map((model) => model.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Result<int>> getBalance({DateTime? before}) {
    return _run(() => _local.getBalance(beforeMillis: before?.millisecondsSinceEpoch));
  }

  @override
  Future<Result<Unit>> addTransaction(TransactionEntity transaction) {
    return _run(() async {
      await _local.insert(TransactionModel.fromEntity(transaction));
      return unit;
    });
  }

  @override
  Future<Result<Unit>> addTransactions(List<TransactionEntity> transactions) {
    return _run(() async {
      await _local.insertAll(transactions.map(TransactionModel.fromEntity).toList(growable: false));
      return unit;
    });
  }

  @override
  Future<Result<Unit>> updateTransaction(TransactionEntity transaction) {
    return _run(() async {
      await _local.update(TransactionModel.fromEntity(transaction));
      return unit;
    });
  }

  @override
  Future<Result<Unit>> deleteTransaction(String id) {
    return _run(() async {
      await _local.delete(id);
      return unit;
    });
  }

  @override
  Future<Result<Unit>> deleteAll() {
    return _run(() async {
      await _local.deleteAll();
      return unit;
    });
  }

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on RecordNotFoundException catch (e) {
      return Err(NotFoundFailure(e.message));
    } on LocalStorageException {
      return Err(const StorageFailure());
    } on ArgumentError {
      // Dado gravado com tipo/categoria desconhecidos.
      return Err(const StorageFailure('Dados corrompidos encontrados.'));
    }
  }
}
