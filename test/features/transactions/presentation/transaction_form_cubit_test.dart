import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAddTransaction addTransaction;
  late MockUpdateTransaction updateTransaction;
  late MockDeleteTransaction deleteTransaction;

  final today = DateTime(2026, 10, 27, 9);

  setUpAll(() {
    registerFallbackValue(expense());
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
    updateTransaction = MockUpdateTransaction();
    deleteTransaction = MockDeleteTransaction();
  });

  TransactionFormCubit build(TransactionFormState initial) => TransactionFormCubit(
    addTransaction: addTransaction,
    updateTransaction: updateTransaction,
    deleteTransaction: deleteTransaction,
    initialState: initial,
  );

  test('trocar o tipo seleciona a categoria padrão do novo tipo', () {
    final cubit = build(TransactionFormState.create(date: today))
      ..typeChanged(TransactionType.income);

    expect(cubit.state.type, TransactionType.income);
    expect(cubit.state.category, TransactionCategory.salary);
  });

  blocTest<TransactionFormCubit, TransactionFormState>(
    'submit inválido apenas exibe os erros de campo',
    build: () => build(TransactionFormState.create(date: today)),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<TransactionFormState>()
          .having((s) => s.showErrors, 'showErrors', isTrue)
          .having((s) => s.titleError, 'titleError', isNotNull)
          .having((s) => s.amountError, 'amountError', isNotNull),
    ],
    verify: (_) => verifyNever(() => addTransaction(any())),
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'submit válido cria a transação',
    setUp: () => when(() => addTransaction(any())).thenAnswer((_) async => Ok(expense())),
    build: () => build(TransactionFormState.create(date: today)),
    act: (cubit) async {
      cubit
        ..titleChanged('Padaria')
        ..amountChanged(2350)
        ..categoryChanged(TransactionCategory.food);
      await cubit.submit();
    },
    skip: 2,
    expect: () => [
      isA<TransactionFormState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<TransactionFormState>().having((s) => s.status, 'status', FormStatus.saved),
    ],
    verify: (_) {
      final params = verify(() => addTransaction(captureAny())).captured.single as AddTransactionParams;
      expect(params.title, 'Padaria');
      expect(params.amountInCents, 2350);
      expect(params.type, TransactionType.expense);
      expect(params.date, today);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'em modo edição usa UpdateTransaction mantendo o id',
    setUp: () => when(() => updateTransaction(any())).thenAnswer((_) async => Ok(expense())),
    build: () => build(TransactionFormState.edit(expense(id: 'abc', cents: 1000))),
    act: (cubit) async {
      cubit.amountChanged(5000);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.status, FormStatus.saved);
      final updated = verify(() => updateTransaction(captureAny())).captured.single;
      expect(updated, expense(id: 'abc', cents: 5000));
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'falha ao salvar expõe a mensagem',
    setUp: () => when(() => addTransaction(any()))
        .thenAnswer((_) async => Err(const StorageFailure('Sem espaço'))),
    build: () => build(
      TransactionFormState.create(date: today).copyWith(title: 'Teste', amountInCents: 100),
    ),
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.status, FormStatus.failure);
      expect(cubit.state.errorMessage, 'Sem espaço');
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'delete remove a transação em edição',
    setUp: () => when(() => deleteTransaction(any())).thenAnswer((_) async => const Ok(unit)),
    build: () => build(TransactionFormState.edit(expense(id: 'abc'))),
    act: (cubit) => cubit.delete(),
    verify: (cubit) {
      expect(cubit.state.status, FormStatus.deleted);
      verify(() => deleteTransaction('abc')).called(1);
    },
  );
}
