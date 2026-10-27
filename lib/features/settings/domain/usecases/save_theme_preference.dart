import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/domain/repositories/settings_repository.dart';

class SaveThemePreference implements UseCase<Unit, ThemePreference> {
  const SaveThemePreference(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<Unit>> call(ThemePreference params) => _repository.saveThemePreference(params);
}
