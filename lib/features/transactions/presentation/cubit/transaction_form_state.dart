part of 'transaction_form_cubit.dart';

enum FormStatus { editing, submitting, saved, deleted, failure }

final class TransactionFormState extends Equatable {
  const TransactionFormState({
    required this.type,
    required this.category,
    required this.date,
    this.original,
    this.title = '',
    this.amountInCents = 0,
    this.note = '',
    this.status = FormStatus.editing,
    this.showErrors = false,
    this.errorMessage,
  });

  /// Estado inicial para criar uma nova transação.
  factory TransactionFormState.create({required DateTime date, TransactionType? type}) {
    final initialType = type ?? TransactionType.expense;
    return TransactionFormState(
      type: initialType,
      category: TransactionCategory.defaultFor(initialType),
      date: date,
    );
  }

  /// Estado inicial para editar uma transação existente.
  factory TransactionFormState.edit(TransactionEntity transaction) {
    return TransactionFormState(
      original: transaction,
      type: transaction.type,
      category: transaction.category,
      date: transaction.date,
      title: transaction.title,
      amountInCents: transaction.amountInCents,
      note: transaction.note ?? '',
    );
  }

  /// Transação em edição; `null` quando é um novo lançamento.
  final TransactionEntity? original;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String title;
  final int amountInCents;
  final String note;
  final FormStatus status;

  /// Só exibe erros de campo depois da primeira tentativa de salvar.
  final bool showErrors;
  final String? errorMessage;

  bool get isEditing => original != null;

  bool get isSubmitting => status == FormStatus.submitting;

  String? get titleError {
    if (!showErrors) return null;
    if (title.trim().isEmpty) return 'Informe uma descrição';
    if (title.trim().length > TransactionValidator.maxTitleLength) {
      return 'Máximo de ${TransactionValidator.maxTitleLength} caracteres';
    }
    return null;
  }

  String? get amountError {
    if (!showErrors) return null;
    if (amountInCents <= 0) return 'Informe um valor maior que zero';
    if (amountInCents > TransactionValidator.maxAmountInCents) return 'Valor acima do limite';
    return null;
  }

  bool get isValid => TransactionValidator.validate(
        title: title,
        amountInCents: amountInCents,
        type: type,
        category: category,
        note: note,
      ) ==
      null;

  TransactionFormState copyWith({
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? title,
    int? amountInCents,
    String? note,
    FormStatus? status,
    bool? showErrors,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionFormState(
      original: original,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      title: title ?? this.title,
      amountInCents: amountInCents ?? this.amountInCents,
      note: note ?? this.note,
      status: status ?? this.status,
      showErrors: showErrors ?? this.showErrors,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    original,
    type,
    category,
    date,
    title,
    amountInCents,
    note,
    status,
    showErrors,
    errorMessage,
  ];
}
