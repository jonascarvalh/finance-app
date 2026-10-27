import 'package:fluxo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:fluxo/features/settings/domain/usecases/save_theme_preference.dart';
import 'package:fluxo/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fluxo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fluxo/features/transactions/domain/usecases/add_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/clear_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_financial_summary.dart';
import 'package:fluxo/features/transactions/domain/usecases/get_month_transactions.dart';
import 'package:fluxo/features/transactions/domain/usecases/load_sample_data.dart';
import 'package:fluxo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:fluxo/features/transactions/domain/usecases/update_transaction.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockTransactionLocalDataSource extends Mock implements TransactionLocalDataSource {}

class MockSettingsLocalDataSource extends Mock implements SettingsLocalDataSource {}

class MockGetMonthTransactions extends Mock implements GetMonthTransactions {}

class MockGetFinancialSummary extends Mock implements GetFinancialSummary {}

class MockAddTransaction extends Mock implements AddTransaction {}

class MockUpdateTransaction extends Mock implements UpdateTransaction {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockLoadSampleData extends Mock implements LoadSampleData {}

class MockClearTransactions extends Mock implements ClearTransactions {}

class MockSaveThemePreference extends Mock implements SaveThemePreference {}
