import 'package:equatable/equatable.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Uma movimentação financeira (entrada ou saída).
///
/// [amountInCents] é sempre positivo; o sinal é dado por [type].
class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amountInCents,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String title;
  final int amountInCents;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;

  bool get isIncome => type.isIncome;

  bool get isExpense => type.isExpense;

  /// Valor com sinal: positivo para entradas, negativo para saídas.
  int get signedAmountInCents => isIncome ? amountInCents : -amountInCents;

  TransactionEntity copyWith({
    String? id,
    String? title,
    int? amountInCents,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  List<Object?> get props => [id, title, amountInCents, type, category, date, note];
}
