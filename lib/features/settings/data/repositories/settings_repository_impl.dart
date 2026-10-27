import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Result<ThemePreference>> getThemePreference() async {
    try {
      final stored = await _local.getThemePreference();
      final preference = ThemePreference.values.asNameMap()[stored] ?? ThemePreference.system;
      return Ok(preference);
    } on LocalStorageException {
      return const Err(StorageFailure('Não foi possível ler as preferências.'));
    }
  }

  @override
  Future<Result<Unit>> saveThemePreference(ThemePreference preference) async {
    try {
      await _local.saveThemePreference(preference.name);
      return const Ok(unit);
    } on LocalStorageException {
      return const Err(StorageFailure('Não foi possível salvar o tema.'));
    }
  }
}
