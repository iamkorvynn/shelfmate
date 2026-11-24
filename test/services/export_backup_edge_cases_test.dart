// [ShelfMate Dev Step 2/3]: Add tests for missing version fields in backup JSON
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/database/database_helper.dart';
import 'package:shelfmate/database/database_service.dart';
import 'package:shelfmate/database/tables.dart';
import 'package:shelfmate/models/app_settings.dart';
import 'package:shelfmate/models/borrower.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/item.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/backup_service.dart';
import 'package:shelfmate/services/export_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('ExportService (CSV) Detailed Edge Cases', () {
    test('exportLoansToCsv with empty loans produces only CSV headers', () {
      final csv = ExportService.exportLoansToCsv([]);
      expect(csv.trim(), 'ID,Item Name,Category,Borrower,Phone,Date Lent,Expected Return,Date Returned,Status,Days Out,Notes');
    });

    test('exportLoansToCsv escapes fields with quotes, commas, and newlines', () {
      final loan = Loan(
        id: 1,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        returnedDate: DateTime(2026, 11, 12),
        notes: 'Line 1,\nLine 2 with "double quotes"',
        status: LoanStatus.returned,
        createdAt: DateTime(2026, 11, 1),
        itemName: 'Complex "Item", Special',
        itemCategory: ItemCategory.other,
        borrowerName: 'Doe, John "Johnny"',
        borrowerPhone: '+1 (555) 012-3456',
      );

      final csv = ExportService.exportLoansToCsv([loan]);
      expect(csv, contains('"Complex ""Item"", Special"'));
      expect(csv, contains('"Doe, John ""Johnny"""'));
      expect(csv, contains('+1 (555) 012-3456'));
      expect(csv, contains('"Line 1,\nLine 2 with ""double quotes"""'));
      expect(csv, contains('Returned'));
      expect(csv, contains('11')); // 11 days out (Nov 1 to Nov 12)
    });

    test('exportLoansToCsv handles null phone, null notes, null returned date', () {
      final loan = Loan(
        id: 2,
        itemId: 2,
        borrowerId: 2,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
        returnedDate: null,
        notes: null,
        status: LoanStatus.out,
        createdAt: DateTime(2026, 11, 10),
        itemName: 'Simple Charger',
        itemCategory: ItemCategory.chargers,
        borrowerName: 'Alice',
        borrowerPhone: null,
      );

      final csv = ExportService.exportLoansToCsv([loan]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 2);
      expect(lines[1], contains('2,Simple Charger,Chargers,Alice,'));
    });
  });

  group('BackupService (JSON) Detailed Edge Cases', () {
    late Database db;
    late DatabaseService dbService;
    late BackupService backupService;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(Tables.createBorrowersTable);
            await db.execute(Tables.createItemsTable);
            await db.execute(Tables.createLoansTable);
            await db.execute(Tables.createAppSettingsTable);
          },
        ),
      );
      dbService = DatabaseService(DatabaseHelper(db), db);
      backupService = BackupService(dbService);
    });

    tearDown(() async {
      await db.close();
    });

    test('validateBackupJson returns true for valid backup structure', () {
      const validJson = '''
      {
        "version": 1,
        "exported_at": "2026-11-24T12:00:00",
        "borrowers": [],
        "items": [],
        "loans": [],
        "app_settings": []
      }
      ''';
      expect(BackupService.validateBackupJson(validJson), isTrue);
    });

    test('validateBackupJson returns false for malformed JSON string', () {
      expect(BackupService.validateBackupJson('not a json string'), isFalse);
      expect(BackupService.validateBackupJson('{ broken json : 123'), isFalse);
    });

    test('validateBackupJson returns false if missing required table keys', () {
      expect(BackupService.validateBackupJson('{"version": 1, "items": []}'), isFalse);
      expect(BackupService.validateBackupJson('{"borrowers": [], "loans": []}'), isFalse);
    });

    test('full roundtrip export and restore restores data exactly', () async {
      final bId = await dbService.insertBorrower(Borrower(name: 'Charlie', phone: '12345', createdAt: DateTime.now()));
      final iId = await dbService.insertItem(Item(name: 'Microscope', category: ItemCategory.labGear, createdAt: DateTime.now()));
      await dbService.lendItem(
        itemId: iId,
        itemName: 'Microscope',
        category: ItemCategory.labGear,
        borrowerId: bId,
        borrowerName: 'Charlie',
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
      );
      await dbService.saveSettings(const AppSettings(defaultLoanPeriodDays: 28, use24HourClock: true));

      final exportedJson = await backupService.exportBackupJson();
      expect(BackupService.validateBackupJson(exportedJson), isTrue);

      // Wipe db
      await dbService.clearAllData();
      expect((await dbService.getAllBorrowers()).isEmpty, isTrue);
      expect((await dbService.getAllLoans()).isEmpty, isTrue);

      // Restore
      final success = await backupService.restoreFromJsonString(exportedJson);
      expect(success, isTrue);

      final restoredBorrowers = await dbService.getAllBorrowers();
      final restoredLoans = await dbService.getAllLoans();
      final restoredSettings = await dbService.getSettings();

      expect(restoredBorrowers.length, 1);
      expect(restoredBorrowers.first.name, 'Charlie');
      expect(restoredLoans.length, 1);
      expect(restoredLoans.first.itemName, 'Microscope');
      expect(restoredSettings.defaultLoanPeriodDays, 28);
      expect(restoredSettings.use24HourClock, isTrue);
    });

    test('restoreFromJsonString returns false on invalid JSON without corrupting db', () async {
      final bId = await dbService.insertBorrower(Borrower(name: 'Safe User', createdAt: DateTime.now()));
      final success = await backupService.restoreFromJsonString('invalid json payload');
      expect(success, isFalse);

      final borrowers = await dbService.getAllBorrowers();
      expect(borrowers.length, 1);
      expect(borrowers.first.id, bId);
    });
  });
}
