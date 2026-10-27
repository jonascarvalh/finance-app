import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo/core/error/exceptions.dart';
import 'package:fluxo/core/error/failures.dart';
import 'package:fluxo/core/result/result.dart';
import 'package:fluxo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:fluxo/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(() => registerFallbackValue(ThemePreference.system));

  group('SettingsLocalDataSourceImpl', () {
    test('lê e grava a preferência no SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = SettingsLocalDataSourceImpl(prefs);

      expect(await dataSource.getThemePreference(), isNull);
      await dataSource.saveThemePreference('dark');
      expect(await dataSource.getThemePreference(), 'dark');
    });
  });

  group('SettingsRepositoryImpl', () {
    late MockSettingsLocalDataSource local;
    late SettingsRepositoryImpl repository;

    setUp(() {
      local = MockSettingsLocalDataSource();
      repository = SettingsRepositoryImpl(local);
    });

    test('usa "sistema" quando não há valor salvo ou o valor é inválido', () async {
      when(() => local.getThemePreference()).thenAnswer((_) async => null);
      expect((await repository.getThemePreference()).valueOrNull, ThemePreference.system);

      when(() => local.getThemePreference()).thenAnswer((_) async => 'roxo');
      expect((await repository.getThemePreference()).valueOrNull, ThemePreference.system);
    });

    test('converte o nome salvo em enum', () async {
      when(() => local.getThemePreference()).thenAnswer((_) async => 'light');
      expect((await repository.getThemePreference()).valueOrNull, ThemePreference.light);
    });

    test('falha ao salvar vira StorageFailure', () async {
      when(() => local.saveThemePreference(any()))
          .thenThrow(const LocalStorageException('erro'));

      final result = await repository.saveThemePreference(ThemePreference.dark);

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('ThemeCubit', () {
    late MockSaveThemePreference save;

    setUp(() {
      save = MockSaveThemePreference();
      when(() => save(any())).thenAnswer((_) async => const Ok(unit));
    });

    blocTest<ThemeCubit, ThemePreference>(
      'aplica e persiste a nova preferência',
      build: () => ThemeCubit(saveThemePreference: save),
      act: (cubit) => cubit.select(ThemePreference.dark),
      expect: () => [ThemePreference.dark],
      verify: (_) => verify(() => save(ThemePreference.dark)).called(1),
    );

    blocTest<ThemeCubit, ThemePreference>(
      'ignora seleção repetida',
      build: () => ThemeCubit(saveThemePreference: save, initial: ThemePreference.light),
      act: (cubit) => cubit.select(ThemePreference.light),
      expect: () => <ThemePreference>[],
      verify: (_) => verifyNever(() => save(any())),
    );

    test('mapeia preferência para ThemeMode', () {
      expect(ThemePreference.dark.themeMode.name, 'dark');
      expect(ThemePreference.system.themeMode.name, 'system');
    });
  });
}
