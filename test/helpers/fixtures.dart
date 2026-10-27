import 'package:fluxo/core/utils/id_generator.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Gerador de ids previsível para testes: `id-1`, `id-2`, ...
class SequentialIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String generate() => 'id-${++_next}';
}

TransactionEntity income({
  String id = 'in-1',
  String title = 'Salário',
  int cents = 500000,
  DateTime? date,
  TransactionCategory category = TransactionCategory.salary,
}) {
  return TransactionEntity(
    id: id,
    title: title,
    amountInCents: cents,
    type: TransactionType.income,
    category: category,
    date: date ?? DateTime(2026, 10, 5, 12),
  );
}

TransactionEntity expense({
  String id = 'out-1',
  String title = 'Mercado',
  int cents = 10000,
  DateTime? date,
  TransactionCategory category = TransactionCategory.food,
  String? note,
}) {
  return TransactionEntity(
    id: id,
    title: title,
    amountInCents: cents,
    type: TransactionType.expense,
    category: category,
    date: date ?? DateTime(2026, 10, 10, 12),
    note: note,
  );
}

/// Remove espaços não separáveis usados pelo `intl` ("R$ 10,00").
String normalizeSpaces(String value) => value.replaceAll(' ', ' ');
