import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/presentation/widgets/empty_state.dart';
import 'package:fluxo/core/presentation/widgets/section_header.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:fluxo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:fluxo/features/transactions/presentation/widgets/balance_card.dart';
import 'package:fluxo/features/transactions/presentation/widgets/category_donut_chart.dart';
import 'package:fluxo/features/transactions/presentation/widgets/month_selector.dart';
import 'package:fluxo/features/transactions/presentation/widgets/monthly_bar_chart.dart';
import 'package:fluxo/features/transactions/presentation/widgets/transaction_tile.dart';

/// Tela inicial: saldo, gráficos e movimentações recentes.
class HomePage extends StatelessWidget {
  const HomePage({required this.onSeeAll, super.key});

  /// Abre a aba de extrato.
  final VoidCallback onSeeAll;

  static const int recentLimit = 5;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        return switch (state.status) {
          TransactionsStatus.initial || TransactionsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          TransactionsStatus.failure => _ErrorView(message: state.errorMessage),
          TransactionsStatus.success => _HomeContent(state: state, onSeeAll: onSeeAll),
        };
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state, required this.onSeeAll});

  final TransactionsState state;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final recent = state.transactions.take(HomePage.recentLimit).toList(growable: false);
    final isEmpty = !summary.hasHistory && state.transactions.isEmpty;

    return RefreshIndicator(
      onRefresh: context.read<TransactionsCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        children: [
          const _Header(),
          const SizedBox(height: 16),
          const MonthSelector(),
          const SizedBox(height: 16),
          BalanceCard(summary: summary),
          const SizedBox(height: 28),
          if (isEmpty)
            const _GettingStarted()
          else ...[
            const SectionHeader(title: 'Últimos 6 meses'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
                child: MonthlyBarChart(history: summary.history, selectedMonth: state.month),
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Gastos por categoria'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: summary.expensesByCategory.isEmpty
                    ? const EmptyState(
                        compact: true,
                        icon: Icons.donut_large_rounded,
                        title: 'Nenhuma saída neste mês',
                        message: 'Quando você registrar gastos, eles aparecem aqui por categoria.',
                      )
                    : CategoryDonutChart(totals: summary.expensesByCategory),
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Movimentações recentes',
              actionLabel: state.transactions.isEmpty ? null : 'Ver todas',
              onAction: onSeeAll,
            ),
            Card(
              child: recent.isEmpty
                  ? const EmptyState(
                      compact: true,
                      icon: Icons.receipt_long_outlined,
                      title: 'Sem movimentações neste mês',
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (final transaction in recent)
                            TransactionTile(
                              transaction: transaction,
                              onTap: () => TransactionFormPage.open(context, transaction: transaction),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.waves_rounded, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fluxo', style: theme.textTheme.titleLarge),
              Text(
                'Suas finanças, sem complicação',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Exibido enquanto não há nenhuma transação registrada.
class _GettingStarted extends StatelessWidget {
  const _GettingStarted();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: EmptyState(
        icon: Icons.insights_rounded,
        title: 'Comece a registrar suas finanças',
        message:
            'Adicione entradas e saídas para ver seu saldo e os gráficos. '
            'Se preferir, carregue dados de exemplo para explorar o app.',
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => TransactionFormPage.open(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova transação'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final error = await context.read<TransactionsCubit>().loadSampleData();
              messenger.showSnackBar(
                SnackBar(content: Text(error ?? 'Dados de exemplo carregados.')),
              );
            },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Dados de exemplo'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Algo deu errado',
        message: message ?? 'Não foi possível carregar seus dados.',
        actions: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: context.read<TransactionsCubit>().load,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
