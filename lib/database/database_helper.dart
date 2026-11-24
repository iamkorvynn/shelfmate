// [ShelfMate Dev Step 2/3]: Implement openDatabase and onCreate table creation callback
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'tables.dart';

class DatabaseHelper {
  static const String dbName = 'shelfmate.db';
  static const int dbVersion = 1;

  Database? _db;

  DatabaseHelper([this._db]);

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.createBorrowersTable);
    await db.execute(Tables.createItemsTable);
    await db.execute(Tables.createLoansTable);
    await db.execute('CREATE INDEX idx_loans_status ON ${Tables.loans}(status);');
    await db.execute('CREATE INDEX idx_loans_borrower ON ${Tables.loans}(borrower_id);');
    await db.execute('CREATE INDEX idx_loans_item ON ${Tables.loans}(item_id);');
    await db.execute('CREATE INDEX idx_loans_expected ON ${Tables.loans}(expected_return_date);');
    await db.execute(Tables.createAppSettingsTable);
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
