import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:sqflite/sqflite.dart';

/// Acesso direto ao SQLite. Lança [LocalStorageException] em caso de erro.
abstract interface class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions({int? startMillis, int? endMillis});

  Future<int> getBalance({int? beforeMillis});

  Future<void> insert(TransactionModel model);

  Future<void> insertAll(List<TransactionModel> models);

  Future<void> update(TransactionModel model);

  Future<void> delete(String id);

  Future<void> deleteAll();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this._db);

  final Database _db;

  static const _table = TransactionFields.table;

  @override
  Future<List<TransactionModel>> getTransactions({int? startMillis, int? endMillis}) {
    return _guard('listar transações', () async {
      final where = <String>[];
      final args = <Object>[];
      if (startMillis != null) {
        where.add('${TransactionFields.date} >= ?');
        args.add(startMillis);
      }
      if (endMillis != null) {
        where.add('${TransactionFields.date} < ?');
        args.add(endMillis);
      }

      final rows = await _db.query(
        _table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: '${TransactionFields.date} DESC, rowid DESC',
      );
      return rows.map(TransactionModel.fromMap).toList(growable: false);
    });
  }

  @override
  Future<int> getBalance({int? beforeMillis}) {
    return _guard('calcular saldo', () async {
      final args = <Object>[TransactionType.income.name];
      var sql =
          'SELECT COALESCE(SUM(CASE WHEN ${TransactionFields.type} = ? '
          'THEN ${TransactionFields.amountInCents} '
          'ELSE -${TransactionFields.amountInCents} END), 0) AS balance '
          'FROM $_table';
      if (beforeMillis != null) {
        sql += ' WHERE ${TransactionFields.date} < ?';
        args.add(beforeMillis);
      }

      final rows = await _db.rawQuery(sql, args);
      final value = rows.first['balance'];
      return value is int ? value : (value as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<void> insert(TransactionModel model) {
    return _guard('salvar transação', () async {
      await _db.insert(_table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> insertAll(List<TransactionModel> models) {
    return _guard('salvar transações', () async {
      final batch = _db.batch();
      for (final model in models) {
        batch.insert(_table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> update(TransactionModel model) {
    return _guard('atualizar transação', () async {
      final count = await _db.update(
        _table,
        model.toMap(),
        where: '${TransactionFields.id} = ?',
        whereArgs: [model.id],
      );
      if (count == 0) {
        throw RecordNotFoundException('Transação ${model.id} não encontrada.');
      }
    });
  }

  @override
  Future<void> delete(String id) {
    return _guard('excluir transação', () async {
      await _db.delete(_table, where: '${TransactionFields.id} = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> deleteAll() {
    return _guard('apagar transações', () async {
      await _db.delete(_table);
    });
  }

  /// Converte qualquer erro do SQLite em [LocalStorageException].
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on LocalStorageException {
      rethrow;
    } on Object catch (error) {
      throw LocalStorageException('Falha ao $action.', error);
    }
  }
}
