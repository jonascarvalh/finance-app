import 'dart:math';

import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/id_generator.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';

/// Popula o app com seis meses de movimentações fictícias, útil para
/// demonstrar os gráficos. Os valores são determinísticos (semente fixa).
class LoadSampleData implements UseCase<int, NoParams> {
  const LoadSampleData(this._repository, this._idGenerator, this._clock);

  final TransactionRepository _repository;
  final IdGenerator _idGenerator;
  final Clock _clock;

  static const int monthsOfData = 6;

  @override
  Future<Result<int>> call(NoParams params) async {
    final transactions = buildSample(now: _clock(), idGenerator: _idGenerator);
    final result = await _repository.addTransactions(transactions);
    return switch (result) {
      Ok() => Ok(transactions.length),
      Err(:final failure) => Err(failure),
    };
  }

  /// Gera os dados sem persistir (exposto para testes).
  static List<TransactionEntity> buildSample({
    required DateTime now,
    required IdGenerator idGenerator,
  }) {
    final random = Random(42);
    final firstMonth = AppDateUtils.addMonths(AppDateUtils.startOfMonth(now), -(monthsOfData - 1));
    final items = <TransactionEntity>[];

    int vary(int baseCents, {double spread = 0.25}) {
      final factor = 1 + (random.nextDouble() * 2 - 1) * spread;
      return (baseCents * factor).round();
    }

    void add(
      DateTime month,
      int day,
      String title,
      int cents,
      TransactionCategory category,
    ) {
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final date = DateTime(month.year, month.month, min(day, lastDay), 12);
      if (date.isAfter(now)) return;
      items.add(
        TransactionEntity(
          id: idGenerator.generate(),
          title: title,
          amountInCents: cents,
          type: category.type,
          category: category,
          date: date,
        ),
      );
    }

    for (var i = 0; i < monthsOfData; i++) {
      final m = AppDateUtils.addMonths(firstMonth, i);

      // Entradas
      add(m, 5, 'Salário', 650000, TransactionCategory.salary);
      if (i.isEven) add(m, 18, 'Projeto freelance', vary(180000, spread: 0.4), TransactionCategory.freelance);
      if (i % 3 == 0) add(m, 25, 'Rendimento CDB', vary(12000), TransactionCategory.investments);

      // Saídas fixas
      add(m, 10, 'Aluguel', 180000, TransactionCategory.housing);
      add(m, 12, 'Internet e celular', 15990, TransactionCategory.bills);
      add(m, 15, 'Conta de luz', vary(21000), TransactionCategory.bills);
      add(m, 8, 'Curso online', 8990, TransactionCategory.education);

      // Saídas variáveis
      add(m, 3, 'Supermercado', vary(62000), TransactionCategory.food);
      add(m, 17, 'Supermercado', vary(48000), TransactionCategory.food);
      add(m, 21, 'Restaurante', vary(14000, spread: 0.5), TransactionCategory.food);
      add(m, 6, 'Combustível', vary(25000), TransactionCategory.transport);
      add(m, 22, 'Aplicativo de transporte', vary(7500, spread: 0.5), TransactionCategory.transport);
      add(m, 14, 'Farmácia', vary(9000, spread: 0.6), TransactionCategory.health);
      add(m, 26, 'Cinema e streaming', vary(11000, spread: 0.4), TransactionCategory.leisure);
      if (i.isOdd) add(m, 20, 'Roupas', vary(32000, spread: 0.5), TransactionCategory.shopping);
    }

    return items;
  }
}
