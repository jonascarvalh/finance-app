import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/presentation/formatters/currency_input_formatter.dart';
import 'package:fluxo/core/theme/finance_colors.dart';
import 'package:fluxo/core/utils/date_utils.dart';
import 'package:fluxo/core/utils/money.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';
import 'package:fluxo/features/transactions/domain/usecases/transaction_validator.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:fluxo/features/transactions/presentation/models/category_presentation.dart';
import 'package:fluxo/injection_container.dart';

/// Formulário para criar ou editar uma transação.
class TransactionFormPage extends StatelessWidget {
  const TransactionFormPage({super.key});

  /// Abre o formulário e, se algo for salvo/excluído, recarrega os dados.
  static Future<void> open(BuildContext context, {TransactionEntity? transaction}) async {
    final transactionsCubit = context.read<TransactionsCubit>();
    final initialState = transaction == null
        ? TransactionFormState.create(date: _defaultDateFor(transactionsCubit.state.month))
        : TransactionFormState.edit(transaction);

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: transaction == null,
        builder: (_) => BlocProvider<TransactionFormCubit>(
          create: (_) => sl<TransactionFormCubit>(param1: initialState),
          child: const TransactionFormPage(),
        ),
      ),
    );

    if (changed ?? false) await transactionsCubit.load();
  }

  /// Hoje, se o mês selecionado for o atual; senão, o 1º dia do mês selecionado.
  static DateTime _defaultDateFor(DateTime selectedMonth) {
    final now = DateTime.now();
    return AppDateUtils.isSameMonth(now, selectedMonth) ? now : selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case FormStatus.saved || FormStatus.deleted:
            Navigator.of(context).pop(true);
          case FormStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Não foi possível salvar.')),
            );
          case FormStatus.editing || FormStatus.submitting:
            break;
        }
      },
      child: const _TransactionFormView(),
    );
  }
}

class _TransactionFormView extends StatelessWidget {
  const _TransactionFormView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final isEditing = cubit.state.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar transação' : 'Nova transação'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: const [
            _TypeSelector(),
            SizedBox(height: 20),
            _AmountField(),
            SizedBox(height: 16),
            _TitleField(),
            SizedBox(height: 8),
            _FieldLabel('Categoria'),
            _CategoryPicker(),
            SizedBox(height: 20),
            _FieldLabel('Data'),
            _DateField(),
            SizedBox(height: 20),
            _NoteField(),
          ],
        ),
      ),
      bottomNavigationBar: const _SaveButton(),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<TransactionFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.delete();
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector();

  @override
  Widget build(BuildContext context) {
    final type = context.select((TransactionFormCubit c) => c.state.type);
    final finance = context.finance;
    final selectedColor = type.isIncome ? finance.incomeContainer : finance.expenseContainer;
    final onSelectedColor = type.isIncome ? finance.onIncomeContainer : finance.onExpenseContainer;

    return SegmentedButton<TransactionType>(
      key: const Key('type_selector'),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: selectedColor,
        selectedForegroundColor: onSelectedColor,
        minimumSize: const Size(0, 48),
      ),
      segments: [
        for (final option in const [TransactionType.expense, TransactionType.income])
          ButtonSegment<TransactionType>(
            value: option,
            icon: Icon(option.icon),
            label: Text(option.label),
          ),
      ],
      selected: {type},
      onSelectionChanged: (selection) =>
          context.read<TransactionFormCubit>().typeChanged(selection.first),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final error = context.select((TransactionFormCubit c) => c.state.amountError);
    final isIncome = context.select((TransactionFormCubit c) => c.state.type.isIncome);
    final theme = Theme.of(context);
    final initial = cubit.state.amountInCents;

    return TextFormField(
      key: const Key('amount_field'),
      initialValue: initial > 0 ? Money.format(initial) : null,
      autofocus: !cubit.state.isEditing,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, const CurrencyInputFormatter()],
      style: theme.textTheme.headlineMedium?.copyWith(
        color: isIncome ? context.finance.income : theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Valor',
        hintText: Money.format(0),
        errorText: error,
        prefixIcon: Icon(isIncome ? Icons.add_rounded : Icons.remove_rounded),
      ),
      onChanged: (text) => cubit.amountChanged(Money.parseCents(text)),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final error = context.select((TransactionFormCubit c) => c.state.titleError);

    return TextFormField(
      key: const Key('title_field'),
      initialValue: cubit.state.title,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      maxLength: TransactionValidator.maxTitleLength,
      decoration: InputDecoration(
        labelText: 'Descrição',
        hintText: 'Ex.: Supermercado, Salário…',
        errorText: error,
        counterText: '',
        prefixIcon: const Icon(Icons.short_text_rounded),
      ),
      onChanged: cubit.titleChanged,
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker();

  @override
  Widget build(BuildContext context) {
    final type = context.select((TransactionFormCubit c) => c.state.type);
    final selected = context.select((TransactionFormCubit c) => c.state.category);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in TransactionCategory.byType(type))
          ChoiceChip(
            selected: category == selected,
            onSelected: (_) => context.read<TransactionFormCubit>().categoryChanged(category),
            avatar: Icon(
              category.icon,
              size: 18,
              color: category == selected ? theme.colorScheme.onSecondaryContainer : category.color,
            ),
            label: Text(category.label),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField();

  @override
  Widget build(BuildContext context) {
    final date = context.select((TransactionFormCubit c) => c.state.date);
    final theme = Theme.of(context);
    final label = AppDateUtils.relativeDayLabel(date, now: DateTime.now());

    return Material(
      color: context.finance.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.finance.subtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pickDate(context, date),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              Text(
                AppDateUtils.fullDate(date),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final cubit = context.read<TransactionFormCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Data da transação',
    );
    if (picked == null) return;
    // Mantém o horário original para preservar a ordenação dentro do dia.
    cubit.dateChanged(
      DateTime(picked.year, picked.month, picked.day, current.hour, current.minute, current.second),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    return TextFormField(
      key: const Key('note_field'),
      initialValue: cubit.state.note,
      minLines: 2,
      maxLines: 4,
      maxLength: TransactionValidator.maxNoteLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Observação (opcional)',
        alignLabelWithHint: true,
      ),
      onChanged: cubit.noteChanged,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select((TransactionFormCubit c) => c.state.isSubmitting);
    final isEditing = context.read<TransactionFormCubit>().state.isEditing;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('save_button'),
          onPressed: isSubmitting ? null : context.read<TransactionFormCubit>().submit,
          child: isSubmitting
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Text(isEditing ? 'Salvar alterações' : 'Adicionar'),
        ),
      ),
    );
  }
}
