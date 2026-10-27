import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';

abstract interface class SettingsRepository {
  Future<Result<ThemePreference>> getThemePreference();

  Future<Result<Unit>> saveThemePreference(ThemePreference preference);
}
