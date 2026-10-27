import 'package:equatable/equatable.dart';
import 'package:fluxo/core/result/result.dart';

/// Contrato de um caso de uso: uma única ação de negócio.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Parâmetro vazio para casos de uso que não recebem entrada.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
