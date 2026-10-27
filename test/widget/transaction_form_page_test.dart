import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/theme/app_theme.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:fluxo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockAddTransaction addTransaction;
  late TransactionFormCubit cubit;
  final today = DateTime(2026, 10, 27, 9);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registerFallbackValue(
      AddTransactionParams(
        title: 'x',
        amountInCents: 1,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: today,
      ),
    );
  });

  setUp(() {
    addTransaction = MockAddTransaction();
    cubit = TransactionFormCubit(
      addTransaction: addTransaction,
      updateTransaction: MockUpdateTransaction(),
      deleteTransaction: MockDeleteTransaction(),
      initialState: TransactionFormState.create(date: today),
    );
  });

  tearDown(() => cubit.close());

  /// Abre o formulário a partir de uma rota inicial, como no app.
  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => BlocProvider<TransactionFormCubit>.value(
                      value: cubit,
                      child: const TransactionFormPage(),
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('exibe erros de validação ao salvar vazio', (tester) async {
    await openForm(tester);

    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pump();

    expect(find.text('Informe uma descrição'), findsOneWidget);
    expect(find.text('Informe um valor maior que zero'), findsOneWidget);
    verifyNever(() => addTransaction(any()));
  });

  testWidgets('aplica máscara de moeda e salva a transação', (tester) async {
    when(() => addTransaction(any())).thenAnswer((_) async => Ok(expense()));
    await openForm(tester);

    await tester.enterText(find.byKey(const Key('amount_field')), '1250');
    await tester.enterText(find.byKey(const Key('title_field')), 'Padaria');
    await tester.pump();

    final amountText = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('amount_field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(normalizeSpaces(amountText.controller.text), r'R$ 12,50');

    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    final params = verify(() => addTransaction(captureAny())).captured.single as AddTransactionParams;
    expect(params.title, 'Padaria');
    expect(params.amountInCents, 1250);
    // O formulário fecha após salvar.
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('alternar para entrada mostra categorias de entrada', (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Entrada'));
    await tester.pump();

    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Alimentação'), findsNothing);
  });
}
