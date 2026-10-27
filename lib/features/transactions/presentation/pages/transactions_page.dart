import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/presentation/widgets/empty_state.dart';
import 'package:fluxo/core/theme/finance_colors.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:fluxo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:fluxo/features/transactions/presentation/widgets/month_selector.dart';
import 'package:fluxo/features/transactions/presentation/widgets/transaction_tile.dart';

/// Extrato do mês: filtro por tipo e lista agrupada por dia.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extrato')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: MonthSelector(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _FilterBar(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<TransactionsCubit, TransactionsState>(
              builder: (context, state) {
                if (state.status == TransactionsStatus.failure) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Algo deu errado',
                    message: state.errorMessage,
                    actions: [
                      FilledButton.tonal(
                        onPressed: context.read<TransactionsCubit>().load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  );
                }
                if (!state.hasLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = state.filteredTransactions;
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: state.filter == TransactionFilter.all
                        ? 'Nenhuma transação neste mês'
                        : 'Nada encontrado com este filtro',
                    message: 'Use o botão + para registrar uma entrada ou saída.',
                  );
                }
                return _GroupedList(transactions: items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final filter = context.select((TransactionsCubit c) => c.state.filter);
    return SegmentedButton<TransactionFilter>(
      key: const Key('filter_bar'),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(value: TransactionFilter.all, label: Text('Todas')),
        ButtonSegment(value: TransactionFilter.income, label: Text('Entradas')),
        ButtonSegment(value: TransactionFilter.expense, label: Text('Saídas')),
      ],
      selected: {filter},
      onSelectionChanged: (selection) =>
          context.read<TransactionsCubit>().setFilter(selection.first),
    );
  }
}

/// Item da lista: cabeçalho de dia ou transação.
sealed class _ListItem {
  const _ListItem();
}

final class _DayHeader extends _ListItem {
  const _DayHeader(this.day, this.totalInCents);

  final DateTime day;
  final int totalInCents;
}

final class _Entry extends _ListItem {
  const _Entry(this.transaction);

  final TransactionEntity transaction;
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.transactions});

  final List<TransactionEntity> transactions;

  /// Intercala cabeçalhos de dia (com o saldo do dia) entre as transações.
  static List<_ListItem> _group(List<TransactionEntity> transactions) {
    final items = <_ListItem>[];
    DateTime? currentDay;
    var headerIndex = -1;
    var dayTotal = 0;

    for (final t in transactions) {
      final day = AppDateUtils.dateOnly(t.date);
      if (currentDay == null || !AppDateUtils.isSameDay(day, currentDay)) {
        if (headerIndex >= 0) items[headerIndex] = _DayHeader(currentDay!, dayTotal);
        currentDay = day;
        dayTotal = 0;
        headerIndex = items.length;
        items.add(_DayHeader(day, 0));
      }
      dayTotal += t.signedAmountInCents;
      items.add(_Entry(t));
    }
    if (headerIndex >= 0) items[headerIndex] = _DayHeader(currentDay!, dayTotal);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _group(transactions);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: context.read<TransactionsCubit>().load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 112),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return switch (items[index]) {
            _DayHeader(:final day, :final totalInCents) => _DayHeaderTile(
              label: AppDateUtils.relativeDayLabel(day, now: now),
              totalInCents: totalInCents,
            ),
            _Entry(:final transaction) => _DismissibleTransaction(transaction: transaction),
          };
        },
      ),
    );
  }
}

class _DayHeaderTile extends StatelessWidget {
  const _DayHeaderTile({required this.label, required this.totalInCents});

  final String label;
  final int totalInCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Money.formatSigned(totalInCents), style: style),
        ],
      ),
    );
  }
}

class _DismissibleTransaction extends StatelessWidget {
  const _DismissibleTransaction({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final finance = context.finance;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: finance.expenseContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: finance.onExpenseContainer),
      ),
      onDismissed: (_) => _delete(context),
      child: TransactionTile(
        transaction: transaction,
        showDate: false,
        onTap: () => TransactionFormPage.open(context, transaction: transaction),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    final error = await cubit.delete(transaction);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${transaction.title}" excluída'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            final restoreError = await cubit.restore(transaction);
            if (restoreError != null) {
              messenger.showSnackBar(SnackBar(content: Text(restoreError)));
            }
          },
        ),
      ),
    );
  }
}
