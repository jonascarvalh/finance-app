import 'package:flutter/material.dart';
import 'package:fluxo/features/settings/presentation/pages/settings_page.dart';
import 'package:fluxo/features/transactions/presentation/pages/home_page.dart';
import 'package:fluxo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:fluxo/features/transactions/presentation/pages/transactions_page.dart';

/// Estrutura principal com navegação inferior entre as abas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final showFab = _index != 2;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            HomePage(onSeeAll: () => _select(1)),
            const TransactionsPage(),
            const SettingsPage(),
          ],
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              key: const Key('add_transaction_fab'),
              tooltip: 'Nova transação',
              onPressed: () => TransactionFormPage.open(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Extrato',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
