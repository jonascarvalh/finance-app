import 'package:flutter/material.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Rótulos, ícones e cores das categorias (preocupação exclusiva da UI).
extension CategoryPresentation on TransactionCategory {
  String get label => switch (this) {
    TransactionCategory.salary => 'Salário',
    TransactionCategory.freelance => 'Freelance',
    TransactionCategory.investments => 'Investimentos',
    TransactionCategory.gift => 'Presente',
    TransactionCategory.otherIncome => 'Outras entradas',
    TransactionCategory.food => 'Alimentação',
    TransactionCategory.housing => 'Moradia',
    TransactionCategory.transport => 'Transporte',
    TransactionCategory.health => 'Saúde',
    TransactionCategory.education => 'Educação',
    TransactionCategory.leisure => 'Lazer',
    TransactionCategory.shopping => 'Compras',
    TransactionCategory.bills => 'Contas',
    TransactionCategory.otherExpense => 'Outras saídas',
  };

  IconData get icon => switch (this) {
    TransactionCategory.salary => Icons.work_outline_rounded,
    TransactionCategory.freelance => Icons.laptop_mac_rounded,
    TransactionCategory.investments => Icons.trending_up_rounded,
    TransactionCategory.gift => Icons.card_giftcard_rounded,
    TransactionCategory.otherIncome => Icons.add_circle_outline_rounded,
    TransactionCategory.food => Icons.restaurant_rounded,
    TransactionCategory.housing => Icons.home_outlined,
    TransactionCategory.transport => Icons.directions_car_outlined,
    TransactionCategory.health => Icons.favorite_outline_rounded,
    TransactionCategory.education => Icons.school_outlined,
    TransactionCategory.leisure => Icons.sports_esports_outlined,
    TransactionCategory.shopping => Icons.shopping_bag_outlined,
    TransactionCategory.bills => Icons.receipt_long_outlined,
    TransactionCategory.otherExpense => Icons.more_horiz_rounded,
  };

  /// Cores de tom médio, legíveis tanto no tema claro quanto no escuro.
  Color get color => switch (this) {
    TransactionCategory.salary => const Color(0xFF22C55E),
    TransactionCategory.freelance => const Color(0xFF06B6D4),
    TransactionCategory.investments => const Color(0xFF10B981),
    TransactionCategory.gift => const Color(0xFFF472B6),
    TransactionCategory.otherIncome => const Color(0xFF84CC16),
    TransactionCategory.food => const Color(0xFFF59E0B),
    TransactionCategory.housing => const Color(0xFF6366F1),
    TransactionCategory.transport => const Color(0xFF0EA5E9),
    TransactionCategory.health => const Color(0xFF14B8A6),
    TransactionCategory.education => const Color(0xFF8B5CF6),
    TransactionCategory.leisure => const Color(0xFFEC4899),
    TransactionCategory.shopping => const Color(0xFFF97316),
    TransactionCategory.bills => const Color(0xFF64748B),
    TransactionCategory.otherExpense => const Color(0xFFA8A29E),
  };
}

extension TransactionTypePresentation on TransactionType {
  String get label => switch (this) {
    TransactionType.income => 'Entrada',
    TransactionType.expense => 'Saída',
  };

  String get pluralLabel => switch (this) {
    TransactionType.income => 'Entradas',
    TransactionType.expense => 'Saídas',
  };

  IconData get icon => switch (this) {
    TransactionType.income => Icons.south_west_rounded,
    TransactionType.expense => Icons.north_east_rounded,
  };
}
