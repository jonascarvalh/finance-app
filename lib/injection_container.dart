import 'package:fluxo/core/usecase/usecase.dart';
import 'package:fluxo/core/utils/id_generator.dart';
import 'package:fluxo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:fluxo/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/domain/repositories/settings_repository.dart';
import 'package:fluxo/features/settings/domain/usecases/get_theme_preference.dart';
import 'package:fluxo/features/settings/domain/usecases/save_theme_preference.dart';
import 'package:fluxo/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_database.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fluxo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/clear_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_financial_summary.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_month_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/load_sample_data.dart';
import 'package:fluxo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/update_transaction.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Service locator da aplicação.
final sl = GetIt.instance;

/// Registra todas as dependências, de fora (infraestrutura) para dentro
/// (apresentação). Chamado uma única vez em `main`.
Future<void> initDependencies() async {
  // ── Externos ────────────────────────────────────────────────────────────
  final database = await TransactionDatabase.open();
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<Database>(database)
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<IdGenerator>(UuidIdGenerator.new)

    // ── Data sources ──────────────────────────────────────────────────────
    ..registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl(sl()))

    // ── Repositórios ──────────────────────────────────────────────────────
    ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(sl()))
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()))

    // ── Casos de uso ──────────────────────────────────────────────────────
    ..registerLazySingleton(() => GetMonthTransactions(sl()))
    ..registerLazySingleton(() => GetFinancialSummary(sl()))
    ..registerLazySingleton(() => AddTransaction(sl(), sl()))
    ..registerLazySingleton(() => UpdateTransaction(sl()))
    ..registerLazySingleton(() => DeleteTransaction(sl()))
    ..registerLazySingleton(() => RestoreTransaction(sl()))
    ..registerLazySingleton(() => ClearTransactions(sl()))
    ..registerLazySingleton(() => LoadSampleData(sl(), sl(), systemClock))
    ..registerLazySingleton(() => GetThemePreference(sl()))
    ..registerLazySingleton(() => SaveThemePreference(sl()))

    // ── Apresentação ──────────────────────────────────────────────────────
    ..registerFactory(
      () => TransactionsCubit(
        getMonthTransactions: sl(),
        getFinancialSummary: sl(),
        deleteTransaction: sl(),
        restoreTransaction: sl(),
        loadSampleData: sl(),
        clearTransactions: sl(),
      ),
    )
    ..registerFactoryParam<TransactionFormCubit, TransactionFormState, void>(
      (initialState, _) => TransactionFormCubit(
        addTransaction: sl(),
        updateTransaction: sl(),
        deleteTransaction: sl(),
        initialState: initialState,
      ),
    );

  final themeResult = await sl<GetThemePreference>()(const NoParams());
  sl.registerFactory(
    () => ThemeCubit(
      saveThemePreference: sl(),
      initial: themeResult.valueOrNull ?? ThemePreference.system,
    ),
  );
}
