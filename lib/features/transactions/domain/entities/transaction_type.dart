/// Direção do dinheiro: entrada (receita) ou saída (despesa).
enum TransactionType {
  income,
  expense;

  bool get isIncome => this == TransactionType.income;

  bool get isExpense => this == TransactionType.expense;
}
