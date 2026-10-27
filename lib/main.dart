import 'package:flutter/material.dart';
import 'package:fluxo/app/app.dart';
import 'package:fluxo/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fluxo/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:fluxo/injection_container.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  await initDependencies();

  runApp(
    FluxoApp(
      createThemeCubit: () => sl<ThemeCubit>(),
      createTransactionsCubit: () => sl<TransactionsCubit>(),
    ),
  );
}
