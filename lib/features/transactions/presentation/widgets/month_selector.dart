import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';

/// Navegação entre meses: `‹  Outubro de 2026  ›`.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    final month = context.select((TransactionsCubit c) => c.state.month);
    final theme = Theme.of(context);
    final label = AppDateUtils.capitalize(AppDateUtils.monthYear(month));
    final canGoNext = cubit.canGoToNextMonth;

    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Mês anterior',
          onPressed: cubit.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canGoNext ? cubit.goToCurrentMonth : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(month),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  if (canGoNext)
                    Text(
                      'Toque para voltar ao mês atual',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Próximo mês',
          onPressed: canGoNext ? cubit.nextMonth : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
