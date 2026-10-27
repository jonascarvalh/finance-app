import 'package:flutter/material.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';

/// Cartão de destaque com saldo acumulado e entradas/saídas do mês.
class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.summary, super.key});

  final FinancialSummary summary;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = Colors.white;
    final monthResult = summary.monthBalanceInCents;

    return Semantics(
      container: true,
      label: 'Saldo acumulado ${Money.format(summary.balanceInCents)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Saldo acumulado',
                    style: textTheme.bodyMedium?.copyWith(color: onCard.withValues(alpha: 0.85)),
                  ),
                  const Spacer(),
                  _ResultPill(cents: monthResult),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money.format(summary.balanceInCents),
                  key: const Key('balance_value'),
                  style: textTheme.headlineLarge?.copyWith(color: onCard),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Entradas',
                      cents: summary.incomeInCents,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Saídas',
                      cents: summary.expenseInCents,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.cents, required this.icon});

  final String label;
  final int cents;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Money.format(cents),
                    style: textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultado do mês (entradas − saídas) em formato de "pílula".
class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.cents});

  final int cents;

  @override
  Widget build(BuildContext context) {
    final positive = cents >= 0;
    return Tooltip(
      message: 'Resultado do mês',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              Money.formatSigned(cents),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
