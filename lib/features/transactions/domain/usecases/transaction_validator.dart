import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_category.dart';
import 'package:fluxo/features/transactions/domain/entities/transaction_type.dart';

/// Regras de negócio para uma transação ser considerada válida.
abstract final class TransactionValidator {
  static const int maxTitleLength = 60;
  static const int maxNoteLength = 200;

  /// Limite de R$ 10 milhões por lançamento.
  static const int maxAmountInCents = 1000000000;

  /// Retorna `null` quando válido, ou a primeira falha encontrada.
  static ValidationFailure? validate({
    required String title,
    required int amountInCents,
    required TransactionType type,
    required TransactionCategory category,
    String? note,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return const ValidationFailure('Informe uma descrição.');
    }
    if (trimmed.length > maxTitleLength) {
      return const ValidationFailure('A descrição deve ter até $maxTitleLength caracteres.');
    }
    if (amountInCents <= 0) {
      return const ValidationFailure('O valor deve ser maior que zero.');
    }
    if (amountInCents > maxAmountInCents) {
      return const ValidationFailure('Valor acima do limite permitido.');
    }
    if (category.type != type) {
      return const ValidationFailure('A categoria não corresponde ao tipo da transação.');
    }
    if (note != null && note.length > maxNoteLength) {
      return const ValidationFailure('A observação deve ter até $maxNoteLength caracteres.');
    }
    return null;
  }
}
