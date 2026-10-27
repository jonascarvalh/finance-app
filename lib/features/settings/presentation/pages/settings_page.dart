import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/presentation/widgets/section_header.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';

/// Preferências do app: tema e gerenciamento de dados.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SectionHeader(title: 'Aparência'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _ThemeSelector(),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Dados'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Carregar dados de exemplo'),
                  subtitle: const Text('Adiciona 6 meses de movimentações fictícias'),
                  onTap: () => _loadSample(context),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
                  title: Text(
                    'Apagar todos os dados',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Remove todas as transações deste dispositivo'),
                  onTap: () => _confirmClear(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Sobre'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Fluxo · versão 1.0.0'),
              subtitle: Text('Seus dados ficam salvos apenas neste aparelho.'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSample(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<TransactionsCubit>().loadSampleData();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Dados de exemplo carregados.')));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Todas as transações serão removidas permanentemente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    final error = await cubit.clearAll();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Todos os dados foram apagados.')));
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final preference = context.watch<ThemeCubit>().state;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Escolha entre claro, escuro ou seguir o sistema.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SegmentedButton<ThemePreference>(
          key: const Key('theme_selector'),
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (final option in ThemePreference.values)
              ButtonSegment<ThemePreference>(
                value: option,
                icon: Icon(option.icon),
                label: Text(option.label),
              ),
          ],
          selected: {preference},
          onSelectionChanged: (selection) async {
            final messenger = ScaffoldMessenger.of(context);
            final error = await context.read<ThemeCubit>().select(selection.first);
            if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
          },
        ),
      ],
    );
  }
}
