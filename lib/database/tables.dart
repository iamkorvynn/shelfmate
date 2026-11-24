// [ShelfMate Dev Step 2/3]: Add CREATE TABLE statements for items, borrowers, and loans
class Tables {
  static const String borrowers = 'borrowers';
  static const String items = 'items';
  static const String loans = 'loans';
  static const String appSettings = 'app_settings';

  static const String createBorrowersTable = '''
    CREATE TABLE $borrowers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createItemsTable = '''
    CREATE TABLE $items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createLoansTable = '''
    CREATE TABLE $loans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER NOT NULL,
      borrower_id INTEGER NOT NULL,
      lent_date TEXT NOT NULL,
      expected_return_date TEXT NOT NULL,
      returned_date TEXT,
      notes TEXT,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (item_id) REFERENCES $items(id) ON DELETE CASCADE,
      FOREIGN KEY (borrower_id) REFERENCES $borrowers(id) ON DELETE CASCADE
    );
  ''';

  static const String createLoansIndexes = '''
    CREATE INDEX idx_loans_status ON $loans(status);
    CREATE INDEX idx_loans_borrower ON $loans(borrower_id);
    CREATE INDEX idx_loans_item ON $loans(item_id);
    CREATE INDEX idx_loans_expected ON $loans(expected_return_date);
  ''';

  static const String createAppSettingsTable = '''
    CREATE TABLE $appSettings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';
}
