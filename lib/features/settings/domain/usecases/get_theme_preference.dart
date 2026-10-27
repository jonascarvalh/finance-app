import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/domain/repositories/settings_repository.dart';

class GetThemePreference implements UseCase<ThemePreference, NoParams> {
  const GetThemePreference(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<ThemePreference>> call(NoParams params) => _repository.getThemePreference();
}
