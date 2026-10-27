import 'package:bloc_test/bloc_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/theme/app_theme.dart';
import 'package:fluxo/features/transactions/domain/entities/financial_summary.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:fluxo/features/transactions/presentation/pages/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}

void main() {
  late MockTransactionsCubit cubit;
  final october = DateTime(2026, 10);

  setUpAll(() => initializeDateFormatting('pt_BR'));

  setUp(() {
    cubit = MockTransactionsCubit();
    when(() => cubit.canGoToNextMonth).thenReturn(false);
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  Future<void> pumpHome(WidgetTester tester, TransactionsState state, {ThemeData? theme}) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: BlocProvider<TransactionsCubit>.value(
          value: cubit,
          child: Scaffold(body: HomePage(onSeeAll: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final populated = TransactionsState(
    month: october,
    status: TransactionsStatus.success,
    transactions: [
      income(id: 'a', title: 'Salário', cents: 650000),
      expense(id: 'b', title: 'Aluguel', cents: 180000, category: TransactionCategory.housing),
    ],
    summary: FinancialSummary(
      month: october,
      balanceInCents: 123456,
      incomeInCents: 650000,
      expenseInCents: 180000,
      history: [
        for (var m = 5; m <= 10; m++)
          MonthlyTotals(month: DateTime(2026, m), incomeInCents: 650000, expenseInCents: 180000),
      ],
      expensesByCategory: const [
        CategoryTotal(category: TransactionCategory.housing, amountInCents: 180000, share: 1),
      ],
    ),
  );

  testWidgets('exibe saldo, gráficos e transações recentes', (tester) async {
    await pumpHome(tester, populated);

    final balance = tester.widget<Text>(find.byKey(const Key('balance_value')));
    expect(normalizeSpaces(balance.data!), r'R$ 1.234,56');

    expect(find.byType(BarChart), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(PieChart), 300);
    expect(find.byType(PieChart), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Salário'), 300);
    expect(find.text('Salário'), findsOneWidget);
  });

  testWidgets('mostra o estado inicial quando não há dados', (tester) async {
    await pumpHome(
      tester,
      TransactionsState(
        month: october,
        status: TransactionsStatus.success,
        summary: FinancialSummary.empty(october),
      ),
    );

    expect(find.text('Comece a registrar suas finanças'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('renderiza no tema escuro sem erros', (tester) async {
    await pumpHome(tester, populated, theme: AppTheme.dark);

    expect(tester.takeException(), isNull);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('mostra indicador de carregamento antes da primeira carga', (tester) async {
    when(() => cubit.state).thenReturn(TransactionsState.initial(october));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TransactionsCubit>.value(
          value: cubit,
          child: Scaffold(body: HomePage(onSeeAll: () {})),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
