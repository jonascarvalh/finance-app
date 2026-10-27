import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluxo/core/theme/finance_colors.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';

/// Barras agrupadas de entradas × saídas por mês.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({required this.history, required this.selectedMonth, super.key});

  final List<MonthlyTotals> history;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.finance;

    final maxCents = history.fold<int>(
      0,
      (current, m) => math.max(current, math.max(m.incomeInCents, m.expenseInCents)),
    );
    final step = niceStep(maxCents / 100);
    final maxY = math.max(step, (maxCents / 100 / step).ceil() * step);

    return Column(
      children: [
        Row(
          children: [
            _LegendDot(color: finance.income, label: 'Entradas'),
            const SizedBox(width: 16),
            _LegendDot(color: finance.expense, label: 'Saídas'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: finance.subtle, strokeWidth: 1, dashArray: const [4, 4]),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: step,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value > maxY) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          Money.formatCompact((value * 100).round()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= history.length) return const SizedBox.shrink();
                      final month = history[index].month;
                      final selected = AppDateUtils.isSameMonth(month, selectedMonth);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          AppDateUtils.shortMonth(month),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final totals = history[group.x];
                    final isIncome = rodIndex == 0;
                    final cents = isIncome ? totals.incomeInCents : totals.expenseInCents;
                    return BarTooltipItem(
                      '${isIncome ? 'Entradas' : 'Saídas'}\n',
                      theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onInverseSurface.withValues(alpha: 0.75),
                      ),
                      children: [
                        TextSpan(
                          text: Money.format(cents),
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < history.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      _rod(history[i].incomeInCents, finance.income, history[i], selectedMonth),
                      _rod(history[i].expenseInCents, finance.expense, history[i], selectedMonth),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }

  BarChartRodData _rod(int cents, Color color, MonthlyTotals totals, DateTime selected) {
    final isSelected = AppDateUtils.isSameMonth(totals.month, selected);
    return BarChartRodData(
      toY: cents / 100,
      color: isSelected ? color : color.withValues(alpha: 0.45),
      width: 10,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    );
  }

  /// Intervalo "redondo" para o eixo Y (1, 2, 2,5 ou 5 × 10ⁿ), com ~4 linhas.
  @visibleForTesting
  static double niceStep(double maxValue) {
    if (maxValue <= 0) return 100;
    final raw = maxValue / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final factor in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      final step = factor * magnitude;
      if (step >= raw) return step;
    }
    return 10 * magnitude;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
