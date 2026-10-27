import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluxo/app/home_shell.dart';
import 'package:fluxo/core/theme/app_theme.dart';
import 'package:fluxo/features/settings/domain/entities/theme_preference.dart';
import 'package:fluxo/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';

/// Raiz do app: provê os cubits globais e configura tema e localização.
class FluxoApp extends StatelessWidget {
  const FluxoApp({
    required this.createThemeCubit,
    required this.createTransactionsCubit,
    super.key,
  });

  /// Fábricas recebidas por parâmetro para facilitar testes de widget.
  final ThemeCubit Function() createThemeCubit;
  final TransactionsCubit Function() createTransactionsCubit;

  static const locale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => createThemeCubit()),
        BlocProvider<TransactionsCubit>(create: (_) => createTransactionsCubit()..load()),
      ],
      child: BlocBuilder<ThemeCubit, ThemePreference>(
        builder: (context, preference) {
          return MaterialApp(
            title: 'Fluxo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: preference.themeMode,
            locale: locale,
            supportedLocales: const [locale],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
