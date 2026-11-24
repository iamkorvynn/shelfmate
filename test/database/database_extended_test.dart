// [ShelfMate Dev Step 3/4]: Add tests for settings persistence across db instances
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
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DatabaseService dbService;

  Borrower createB({int? id, required String name, String? phone}) {
    return Borrower(
      id: id,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
  }

  Item createI({int? id, required String name, required ItemCategory category, String? notes}) {
    return Item(
      id: id,
      name: name,
      category: category,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute(Tables.createBorrowersTable);
          await db.execute(Tables.createItemsTable);
          await db.execute(Tables.createLoansTable);
          await db.execute('CREATE INDEX idx_loans_status ON ${Tables.loans}(status);');
          await db.execute('CREATE INDEX idx_loans_borrower ON ${Tables.loans}(borrower_id);');
          await db.execute('CREATE INDEX idx_loans_item ON ${Tables.loans}(item_id);');
          await db.execute('CREATE INDEX idx_loans_expected ON ${Tables.loans}(expected_return_date);');
          await db.execute(Tables.createAppSettingsTable);
        },
      ),
    );
    dbService = DatabaseService(DatabaseHelper(db), db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Extended - Borrowers Edge Cases', () {
    test('insert borrower with unicode name and emojis', () async {
      final b = createB(name: 'José 🚀 日本語', phone: '+81-90-1234-5678');
      final id = await dbService.insertBorrower(b);
      final fetched = await dbService.getBorrower(id);
      expect(fetched?.name, 'José 🚀 日本語');
      expect(fetched?.phone, '+81-90-1234-5678');
    });

    test('insert borrower with single quotes and double quotes in name', () async {
      final b = createB(name: "O'Connor \"The Boss\"", phone: '123');
      final id = await dbService.insertBorrower(b);
      final fetched = await dbService.getBorrower(id);
      expect(fetched?.name, "O'Connor \"The Boss\"");
    });

    test('update non-existent borrower returns 0 affected rows', () async {
      final b = createB(id: 99999, name: 'Ghost', phone: null);
      final count = await dbService.updateBorrower(b);
      expect(count, 0);
    });

    test('delete non-existent borrower returns 0 affected rows', () async {
      final count = await dbService.deleteBorrower(99999);
      expect(count, 0);
    });

    test('get non-existent borrower returns null', () async {
      final b = await dbService.getBorrower(99999);
      expect(b, isNull);
    });

    test('borrower active and total loan counts update correctly across returns', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Multi-Loan Friend'));
      final i1 = await dbService.insertItem(createI(name: 'Item 1', category: ItemCategory.books));
      final i2 = await dbService.insertItem(createI(name: 'Item 2', category: ItemCategory.notes));

      final l1 = await dbService.lendItem(
        itemId: i1,
        itemName: 'Item 1',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Multi-Loan Friend',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
      );
      final l2 = await dbService.lendItem(
        itemId: i2,
        itemName: 'Item 2',
        category: ItemCategory.notes,
        borrowerId: bId,
        borrowerName: 'Multi-Loan Friend',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      var borrower = await dbService.getBorrower(bId);
      expect(borrower?.activeLoansCount, 2);
      expect(borrower?.totalLoansCount, 2);

      // Return one loan
      await dbService.markReturned(l1.id!, DateTime.now());
      borrower = await dbService.getBorrower(bId);
      expect(borrower?.activeLoansCount, 1);
      expect(borrower?.totalLoansCount, 2);

      // Return second loan
      await dbService.markReturned(l2.id!, DateTime.now());
      borrower = await dbService.getBorrower(bId);
      expect(borrower?.activeLoansCount, 0);
      expect(borrower?.totalLoansCount, 2);
    });
  });

  group('Database Extended - Items Edge Cases', () {
    test('insert item with long multiline notes and special symbols', () async {
      final notes = 'Line 1\nLine 2: ~!@#\$%^&*()_+\nLine 3: <html>test</html>';
      final item = createI(name: 'Oscilloscope X1', category: ItemCategory.labGear, notes: notes);
      final id = await dbService.insertItem(item);
      final fetched = await dbService.getItem(id);
      expect(fetched?.notes, notes);
    });

    test('get non-existent item returns null', () async {
      final item = await dbService.getItem(99999);
      expect(item, isNull);
    });

    test('update non-existent item returns 0', () async {
      final count = await dbService.updateItem(createI(id: 99999, name: 'None', category: ItemCategory.other));
      expect(count, 0);
    });

    test('delete non-existent item returns 0', () async {
      final count = await dbService.deleteItem(99999);
      expect(count, 0);
    });

    test('getAvailableItems correctly excludes items currently lent out', () async {
      await dbService.insertItem(createI(name: 'Laptop Charger', category: ItemCategory.chargers));
      final i2 = await dbService.insertItem(createI(name: 'Calculus Book', category: ItemCategory.books));
      await dbService.insertItem(createI(name: 'Multimeter', category: ItemCategory.labGear));

      var available = await dbService.getAvailableItems();
      expect(available.length, 3);

      // Lend out i2
      final loan = await dbService.lendItem(
        itemId: i2,
        itemName: 'Calculus Book',
        category: ItemCategory.books,
        borrowerName: 'Dan',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
      );

      available = await dbService.getAvailableItems();
      expect(available.length, 2);
      expect(available.map((i) => i.id).contains(i2), isFalse);

      // Mark i2 returned -> available again
      await dbService.markReturned(loan.id!, DateTime.now());
      available = await dbService.getAvailableItems();
      expect(available.length, 3);
      expect(available.map((i) => i.id).contains(i2), isTrue);
    });
  });

  group('Database Extended - Loans Edge Cases', () {
    test('get non-existent loan returns null', () async {
      final loan = await dbService.getLoan(99999);
      expect(loan, isNull);
    });

    test('update non-existent loan returns 0', () async {
      final l = Loan(
        id: 99999,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now(),
        status: LoanStatus.out,
        createdAt: DateTime.now(),
      );
      final count = await dbService.updateLoan(l);
      expect(count, 0);
    });

    test('delete non-existent loan returns 0', () async {
      final count = await dbService.deleteLoan(99999);
      expect(count, 0);
    });

    test('lendItem reuses existing borrower with case-insensitive name match', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Harry Potter'));
      final loan = await dbService.lendItem(
        itemName: 'Wand',
        category: ItemCategory.other,
        borrowerName: 'harry potter',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(loan.borrowerId, bId);
      final allBorrowers = await dbService.getAllBorrowers();
      expect(allBorrowers.length, 1);
    });

    test('loans are ordered by expected return date in getActiveLoans', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Ron'));
      final now = DateTime.now();

      await dbService.lendItem(
        itemName: 'Item Late',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Ron',
        lentDate: now,
        expectedReturnDate: now.add(const Duration(days: 10)),
      );
      await dbService.lendItem(
        itemName: 'Item Early',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Ron',
        lentDate: now,
        expectedReturnDate: now.add(const Duration(days: 1)),
      );
      await dbService.lendItem(
        itemName: 'Item Middle',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Ron',
        lentDate: now,
        expectedReturnDate: now.add(const Duration(days: 5)),
      );

      final active = await dbService.getActiveLoans();
      expect(active.length, 3);
      expect(active[0].itemName, 'Item Early');
      expect(active[1].itemName, 'Item Middle');
      expect(active[2].itemName, 'Item Late');
    });

    test('returned loans are ordered by returned date descending', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Ginny'));
      final now = DateTime.now();

      final l1 = await dbService.lendItem(
        itemName: 'Book 1',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Ginny',
        lentDate: now.subtract(const Duration(days: 10)),
        expectedReturnDate: now.subtract(const Duration(days: 5)),
      );
      final l2 = await dbService.lendItem(
        itemName: 'Book 2',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Ginny',
        lentDate: now.subtract(const Duration(days: 10)),
        expectedReturnDate: now.subtract(const Duration(days: 5)),
      );

      await dbService.markReturned(l1.id!, now.subtract(const Duration(days: 3)));
      await dbService.markReturned(l2.id!, now.subtract(const Duration(days: 1)));

      final returned = await dbService.getReturnedLoans();
      expect(returned.length, 2);
      expect(returned.first.itemName, 'Book 2');
      expect(returned.last.itemName, 'Book 1');
    });

    test('cascade deletion of borrower removes all associated loans', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Doomed Friend'));
      await dbService.lendItem(
        itemName: 'Doomed Item 1',
        category: ItemCategory.notes,
        borrowerId: bId,
        borrowerName: 'Doomed Friend',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );
      await dbService.lendItem(
        itemName: 'Doomed Item 2',
        category: ItemCategory.notes,
        borrowerId: bId,
        borrowerName: 'Doomed Friend',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect((await dbService.getAllLoans()).length, 2);

      await dbService.deleteBorrower(bId);
      expect((await dbService.getAllLoans()).isEmpty, isTrue);
    });

    test('cascade deletion of item removes all associated loans', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Borrower X'));
      final itemId = await dbService.insertItem(createI(name: 'Unique Item', category: ItemCategory.labGear));

      await dbService.lendItem(
        itemId: itemId,
        itemName: 'Unique Item',
        category: ItemCategory.labGear,
        borrowerId: bId,
        borrowerName: 'Borrower X',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect((await dbService.getAllLoans()).length, 1);
      await dbService.deleteItem(itemId);
      expect((await dbService.getAllLoans()).isEmpty, isTrue);
    });
  });

  group('Database Extended - Settings & Persistence', () {
    test('saveSettings persists non-default loanPeriodDays and 24h clock', () async {
      const customSettings = AppSettings(
        defaultLoanPeriodDays: 21,
        reminderHour: 18,
        reminderMinute: 45,
        use24HourClock: true,
      );

      await dbService.saveSettings(customSettings);
      final loaded = await dbService.getSettings();

      expect(loaded.defaultLoanPeriodDays, 21);
      expect(loaded.reminderHour, 18);
      expect(loaded.reminderMinute, 45);
      expect(loaded.use24HourClock, isTrue);
    });

    test('clearAllData wipes borrowers, items, loans and resets settings', () async {
      final bId = await dbService.insertBorrower(createB(name: 'Alice'));
      await dbService.lendItem(
        itemName: 'Book',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Alice',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );
      await dbService.saveSettings(const AppSettings(defaultLoanPeriodDays: 30));

      expect((await dbService.getAllBorrowers()).length, 1);
      expect((await dbService.getAllItems()).length, 1);
      expect((await dbService.getAllLoans()).length, 1);

      await dbService.clearAllData();

      expect((await dbService.getAllBorrowers()).isEmpty, isTrue);
      expect((await dbService.getAllItems()).isEmpty, isTrue);
      expect((await dbService.getAllLoans()).isEmpty, isTrue);
      expect((await dbService.getSettings()).defaultLoanPeriodDays, 14); // default
    });
  });
}
