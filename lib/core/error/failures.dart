import 'package:equatable/equatable.dart';

/// Falha de negócio/infraestrutura exposta pelas camadas de domínio e dados.
///
/// Os repositórios convertem exceções técnicas em [Failure]s para que a
/// camada de apresentação nunca dependa de detalhes de implementação.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Erro ao ler ou gravar no armazenamento local (SQLite, preferências).
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Não foi possível acessar os dados.']);
}

/// Dados inválidos informados pelo usuário.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Recurso solicitado não existe.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Registro não encontrado.']);
}
