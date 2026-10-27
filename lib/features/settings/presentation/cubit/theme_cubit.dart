import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/domain/usecases/save_theme_preference.dart';

/// Mantém a preferência de tema e a persiste a cada alteração.
class ThemeCubit extends Cubit<ThemePreference> {
  ThemeCubit({
    required SaveThemePreference saveThemePreference,
    ThemePreference initial = ThemePreference.system,
  }) : _saveThemePreference = saveThemePreference,
       super(initial);

  final SaveThemePreference _saveThemePreference;

  /// Aplica a preferência imediatamente; a gravação acontece em seguida.
  /// Retorna a mensagem de erro, se a gravação falhar.
  Future<String?> select(ThemePreference preference) async {
    if (preference == state) return null;
    emit(preference);
    final result = await _saveThemePreference(preference);
    return result.failureOrNull?.message;
  }
}

extension ThemePreferenceX on ThemePreference {
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  String get label => switch (this) {
    ThemePreference.system => 'Sistema',
    ThemePreference.light => 'Claro',
    ThemePreference.dark => 'Escuro',
  };

  IconData get icon => switch (this) {
    ThemePreference.system => Icons.brightness_auto_outlined,
    ThemePreference.light => Icons.light_mode_outlined,
    ThemePreference.dark => Icons.dark_mode_outlined,
  };
}
