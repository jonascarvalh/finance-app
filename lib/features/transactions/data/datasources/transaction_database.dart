import 'package:flutter/foundation.dart';
import 'package:fluxo/features/transactions/data/models/transaction_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;

/// Abre e versiona o banco SQLite das transações.
abstract final class TransactionDatabase {
  static const fileName = 'fluxo.db';
  static const version = 1;

  /// Windows e Linux não têm o plugin nativo do sqflite: usam a
  /// implementação via FFI. Android, iOS e macOS usam o plugin.
  static bool get _usesFfi =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Abre o banco. [factory] e [path] podem ser trocados em testes
  /// (ex.: `databaseFactoryFfi` e `inMemoryDatabasePath`).
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final DatabaseFactory dbFactory;
    if (factory != null) {
      dbFactory = factory;
    } else if (_usesFfi) {
      sqfliteFfiInit();
      dbFactory = databaseFactoryFfi;
    } else {
      dbFactory = databaseFactorySqflitePlugin;
    }

    final dbPath = path ?? await _defaultPath(dbFactory);
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: version, onCreate: _onCreate),
    );
  }

  static Future<String> _defaultPath(DatabaseFactory dbFactory) async {
    // No desktop, salva na pasta de dados do app (ex.: %APPDATA% no Windows,
    // ~/.local/share no Linux) em vez do diretório de trabalho atual.
    final directory = _usesFfi
        ? (await getApplicationSupportDirectory()).path
        : await dbFactory.getDatabasesPath();
    return p.join(directory, fileName);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE ${TransactionFields.table} (
          ${TransactionFields.id} TEXT PRIMARY KEY NOT NULL,
          ${TransactionFields.title} TEXT NOT NULL,
          ${TransactionFields.amountInCents} INTEGER NOT NULL CHECK (${TransactionFields.amountInCents} > 0),
          ${TransactionFields.type} TEXT NOT NULL,
          ${TransactionFields.category} TEXT NOT NULL,
          ${TransactionFields.date} INTEGER NOT NULL,
          ${TransactionFields.note} TEXT
        )
      ''')
      ..execute(
        'CREATE INDEX idx_${TransactionFields.table}_${TransactionFields.date} '
        'ON ${TransactionFields.table} (${TransactionFields.date})',
      );
    await batch.commit(noResult: true);
  }
}
