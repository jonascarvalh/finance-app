import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Representação de uma transação na camada de dados (linha do SQLite).
///
/// Mantida separada de [TransactionEntity] para que mudanças no formato de
/// persistência não vazem para o domínio.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amountInCents,
    required this.type,
    required this.category,
    required this.dateMillis,
    this.note,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      amountInCents: entity.amountInCents,
      type: entity.type.name,
      category: entity.category.name,
      dateMillis: entity.date.millisecondsSinceEpoch,
      note: entity.note,
    );
  }

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map[TransactionFields.id]! as String,
      title: map[TransactionFields.title]! as String,
      amountInCents: map[TransactionFields.amountInCents]! as int,
      type: map[TransactionFields.type]! as String,
      category: map[TransactionFields.category]! as String,
      dateMillis: map[TransactionFields.date]! as int,
      note: map[TransactionFields.note] as String?,
    );
  }

  final String id;
  final String title;
  final int amountInCents;
  final String type;
  final String category;
  final int dateMillis;
  final String? note;

  Map<String, Object?> toMap() {
    return {
      TransactionFields.id: id,
      TransactionFields.title: title,
      TransactionFields.amountInCents: amountInCents,
      TransactionFields.type: type,
      TransactionFields.category: category,
      TransactionFields.date: dateMillis,
      TransactionFields.note: note,
    };
  }

  /// Converte para entidade. Lança [ArgumentError] se o tipo ou a categoria
  /// gravados não existirem mais no enum.
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      title: title,
      amountInCents: amountInCents,
      type: TransactionType.values.byName(type),
      category: TransactionCategory.values.byName(category),
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      note: note,
    );
  }
}

/// Nomes de tabela e colunas, centralizados para evitar *strings* soltas.
abstract final class TransactionFields {
  static const table = 'transactions';
  static const id = 'id';
  static const title = 'title';
  static const amountInCents = 'amount_cents';
  static const type = 'type';
  static const category = 'category';
  static const date = 'date';
  static const note = 'note';
}
