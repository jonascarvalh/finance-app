import 'package:flutter/material.dart';
import 'package:fluxo/core/theme/finance_colors.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/presentation/models/category_presentation.dart';

/// Linha de uma transação: ícone da categoria, descrição e valor.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, this.showDate = true, super.key});

  final TransactionEntity transaction;
  final VoidCallback? onTap;

  /// Exibe a data no subtítulo (desnecessário quando a lista já agrupa por dia).
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = transaction.category;
    final amountColor = transaction.isIncome ? context.finance.income : theme.colorScheme.onSurface;
    final subtitle = showDate
        ? '${category.label} · ${AppDateUtils.dayMonth(transaction.date)}'
        : category.label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              Money.formatSigned(transaction.signedAmountInCents),
              style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
