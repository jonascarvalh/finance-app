import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluxo/core/theme/finance_colors.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/presentation/models/category_presentation.dart';

/// Gráfico de rosca com os gastos do mês por categoria e legenda detalhada.
class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({required this.totals, super.key});

  /// Totais ordenados do maior para o menor.
  final List<CategoryTotal> totals;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totals != widget.totals) _touchedIndex = null;
  }

  void _toggle(int index) {
    setState(() => _touchedIndex = _touchedIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = widget.totals;
    final grandTotal = totals.fold<int>(0, (sum, t) => sum + t.amountInCents);
    final touched = _touchedIndex == null ? null : totals[_touchedIndex!];

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 62,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final index = response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (index >= 0) _toggle(index);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < totals.length; i++)
                      PieChartSectionData(
                        value: totals[i].amountInCents.toDouble(),
                        color: _touchedIndex == null || _touchedIndex == i
                            ? totals[i].category.color
                            : totals[i].category.color.withValues(alpha: 0.3),
                        radius: _touchedIndex == i ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
              ),
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched?.category.label ?? 'Total de saídas',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Money.format(touched?.amountInCents ?? grandTotal),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (touched != null)
                      Text(
                        _percent(touched.share),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < totals.length; i++)
          _LegendRow(
            total: totals[i],
            highlighted: _touchedIndex == null || _touchedIndex == i,
            onTap: () => _toggle(i),
          ),
      ],
    );
  }
}

String _percent(double share) {
  final value = share * 100;
  return '${value < 10 ? value.toStringAsFixed(1).replaceAll('.', ',') : value.round()}%';
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.total, required this.highlighted, required this.onTap});

  final CategoryTotal total;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = total.category.color;

    return AnimatedOpacity(
      opacity: highlighted ? 1 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(total.category.icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(total.category.label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    _percent(total.share),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(Money.format(total.amountInCents), style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total.share,
                  minHeight: 4,
                  color: color,
                  backgroundColor: context.finance.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
