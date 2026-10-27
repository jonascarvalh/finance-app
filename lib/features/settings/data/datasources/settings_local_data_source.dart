import 'package:fluxo/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistência de preferências simples (chave/valor).
abstract interface class SettingsLocalDataSource {
  /// Retorna o nome salvo do tema ou `null` se nunca foi definido.
  Future<String?> getThemePreference();

  Future<void> saveThemePreference(String value);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  const SettingsLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const themeKey = 'settings.theme_preference';

  @override
  Future<String?> getThemePreference() async => _prefs.getString(themeKey);

  @override
  Future<void> saveThemePreference(String value) async {
    final saved = await _prefs.setString(themeKey, value);
    if (!saved) {
      throw const LocalStorageException('Não foi possível salvar o tema.');
    }
  }
}
