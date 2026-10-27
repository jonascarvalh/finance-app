import 'package:uuid/uuid.dart';

/// Abstração para geração de identificadores únicos (facilita testes).
abstract interface class IdGenerator {
  String generate();
}

final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator([this._uuid = const Uuid()]);

  final Uuid _uuid;

  @override
  String generate() => _uuid.v4();
}

/// Fonte de "agora" injetável, para testes determinísticos.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();
