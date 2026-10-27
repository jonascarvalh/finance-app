import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Categorias disponíveis. Cada categoria pertence a um único [TransactionType].
///
/// Rótulos, ícones e cores ficam na camada de apresentação
/// (`CategoryPresentation`), mantendo o domínio livre de Flutter.
enum TransactionCategory {
  // Entradas
  salary(TransactionType.income),
  freelance(TransactionType.income),
  investments(TransactionType.income),
  gift(TransactionType.income),
  otherIncome(TransactionType.income),

  // Saídas
  food(TransactionType.expense),
  housing(TransactionType.expense),
  transport(TransactionType.expense),
  health(TransactionType.expense),
  education(TransactionType.expense),
  leisure(TransactionType.expense),
  shopping(TransactionType.expense),
  bills(TransactionType.expense),
  otherExpense(TransactionType.expense);

  const TransactionCategory(this.type);

  final TransactionType type;

  static List<TransactionCategory> byType(TransactionType type) =>
      values.where((category) => category.type == type).toList(growable: false);

  /// Categoria padrão sugerida ao alternar o tipo no formulário.
  static TransactionCategory defaultFor(TransactionType type) => switch (type) {
    TransactionType.income => TransactionCategory.salary,
    TransactionType.expense => TransactionCategory.food,
  };
}
