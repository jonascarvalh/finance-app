/// Exceção lançada pelos data sources locais.
///
/// Fica restrita à camada de dados: os repositórios a convertem em
/// `StorageFailure` antes de chegar ao domínio.
class LocalStorageException implements Exception {
  const LocalStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'LocalStorageException: $message${cause != null ? ' ($cause)' : ''}';
}

/// O registro que se tentou alterar não existe.
class RecordNotFoundException extends LocalStorageException {
  const RecordNotFoundException(super.message);
}
