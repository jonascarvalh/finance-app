import 'package:flutter/material.dart';

/// Cores semânticas de finanças (entrada/saída) que não existem no
/// [ColorScheme] padrão. Registradas como [ThemeExtension] para variar entre
/// os temas claro e escuro.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.onIncomeContainer,
    required this.incomeContainer,
    required this.expense,
    required this.onExpenseContainer,
    required this.expenseContainer,
    required this.card,
    required this.subtle,
  });

  static const light = FinanceColors(
    income: Color(0xFF15803D),
    incomeContainer: Color(0xFFDCFCE7),
    onIncomeContainer: Color(0xFF14532D),
    expense: Color(0xFFDC2626),
    expenseContainer: Color(0xFFFEE2E2),
    onExpenseContainer: Color(0xFF7F1D1D),
    card: Color(0xFFFFFFFF),
    subtle: Color(0xFFE7E8EE),
  );

  static const dark = FinanceColors(
    income: Color(0xFF4ADE80),
    incomeContainer: Color(0xFF113321),
    onIncomeContainer: Color(0xFFBBF7D0),
    expense: Color(0xFFF87171),
    expenseContainer: Color(0xFF3B1517),
    onExpenseContainer: Color(0xFFFECACA),
    card: Color(0xFF171A20),
    subtle: Color(0xFF262A33),
  );

  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;

  /// Fundo dos cartões (um pouco acima da superfície da tela).
  final Color card;

  /// Linhas de grade, divisores e trilhas de progresso.
  final Color subtle;

  @override
  FinanceColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? onExpenseContainer,
    Color? card,
    Color? subtle,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
      card: card ?? this.card,
      subtle: subtle ?? this.subtle,
    );
  }

  @override
  FinanceColors lerp(covariant ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(onIncomeContainer, other.onIncomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(expenseContainer, other.expenseContainer, t)!,
      onExpenseContainer: Color.lerp(onExpenseContainer, other.onExpenseContainer, t)!,
      card: Color.lerp(card, other.card, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
    );
  }
}

extension FinanceColorsX on BuildContext {
  /// Atalho: `context.finance.income`.
  FinanceColors get finance => Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}
