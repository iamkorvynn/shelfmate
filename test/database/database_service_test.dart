// [ShelfMate Dev Step 2/4]: Add tests for DatabaseService borrower operations
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
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseService dbService;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
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
    final helper = DatabaseHelper(db);
    dbService = DatabaseService(helper);
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseService - Borrowers', () {
    test('insert and get borrower', () async {
      final borrower = Borrower(
        name: 'Alice Cooper',
        phone: '555-1234',
        createdAt: DateTime(2026, 11, 24),
      );
      final id = await dbService.insertBorrower(borrower);
      expect(id, isPositive);

      final fetched = await dbService.getBorrower(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Alice Cooper');
      expect(fetched.phone, '555-1234');
      expect(fetched.activeLoansCount, 0);
      expect(fetched.totalLoansCount, 0);
    });

    test('update borrower', () async {
      final id = await dbService.insertBorrower(
        Borrower(name: 'Bob', createdAt: DateTime.now()),
      );
      final fetched = await dbService.getBorrower(id);
      final updated = fetched!.copyWith(name: 'Bob Marley', phone: '123-999');
      await dbService.updateBorrower(updated);

      final fetchedAfter = await dbService.getBorrower(id);
      expect(fetchedAfter!.name, 'Bob Marley');
      expect(fetchedAfter.phone, '123-999');
    });

    test('delete borrower', () async {
      final id = await dbService.insertBorrower(
        Borrower(name: 'Charlie', createdAt: DateTime.now()),
      );
      expect(await dbService.getBorrower(id), isNotNull);
      await dbService.deleteBorrower(id);
      expect(await dbService.getBorrower(id), isNull);
    });

    test('getAllBorrowers returns alphabetical order with counts', () async {
      await dbService.insertBorrower(Borrower(name: 'Zoe', createdAt: DateTime.now()));
      await dbService.insertBorrower(Borrower(name: 'Adam', createdAt: DateTime.now()));

      final all = await dbService.getAllBorrowers();
      expect(all.length, 2);
      expect(all.first.name, 'Adam');
      expect(all.last.name, 'Zoe');
    });
  });

  group('DatabaseService - Items', () {
    test('insert and get item', () async {
      final item = Item(
        name: 'Digital Multimeter',
        category: ItemCategory.labGear,
        notes: 'Room 302',
        createdAt: DateTime(2026, 11, 24),
      );
      final id = await dbService.insertItem(item);
      expect(id, isPositive);

      final fetched = await dbService.getItem(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Digital Multimeter');
      expect(fetched.category, ItemCategory.labGear);
      expect(fetched.notes, 'Room 302');
    });

    test('update item', () async {
      final id = await dbService.insertItem(
        Item(name: 'Phone Charger', category: ItemCategory.chargers, createdAt: DateTime.now()),
      );
      final fetched = await dbService.getItem(id);
      await dbService.updateItem(fetched!.copyWith(name: 'Fast Charger 65W'));

      final updated = await dbService.getItem(id);
      expect(updated!.name, 'Fast Charger 65W');
    });

    test('delete item', () async {
      final id = await dbService.insertItem(
        Item(name: 'Old Book', category: ItemCategory.books, createdAt: DateTime.now()),
      );
      expect(await dbService.getItem(id), isNotNull);
      await dbService.deleteItem(id);
      expect(await dbService.getItem(id), isNull);
    });

    test('getAvailableItems excludes items currently out', () async {
      final itemId1 = await dbService.insertItem(
        Item(name: 'Book Out', category: ItemCategory.books, createdAt: DateTime.now()),
      );
      final itemId2 = await dbService.insertItem(
        Item(name: 'Book Available', category: ItemCategory.books, createdAt: DateTime.now()),
      );
      final borrowerId = await dbService.insertBorrower(
        Borrower(name: 'David', createdAt: DateTime.now()),
      );

      // Lend item 1 out
      await dbService.createLoan(
        Loan(
          itemId: itemId1,
          borrowerId: borrowerId,
          lentDate: DateTime.now(),
          expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
          status: LoanStatus.out,
          createdAt: DateTime.now(),
        ),
      );

      final available = await dbService.getAvailableItems();
      expect(available.length, 1);
      expect(available.first.id, itemId2);
    });
  });

  group('DatabaseService - Loans', () {
    test('create and query loan with joined fields', () async {
      final itemId = await dbService.insertItem(
        Item(name: 'Data Structures Book', category: ItemCategory.books, createdAt: DateTime.now()),
      );
      final borrowerId = await dbService.insertBorrower(
        Borrower(name: 'Emma Watson', phone: '555-8888', createdAt: DateTime.now()),
      );

      final loan = Loan(
        itemId: itemId,
        borrowerId: borrowerId,
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 27),
        status: LoanStatus.out,
        createdAt: DateTime(2026, 11, 20),
      );
      final loanId = await dbService.createLoan(loan);
      expect(loanId, isPositive);

      final fetched = await dbService.getLoan(loanId);
      expect(fetched, isNotNull);
      expect(fetched!.itemName, 'Data Structures Book');
      expect(fetched.itemCategory, ItemCategory.books);
      expect(fetched.borrowerName, 'Emma Watson');
      expect(fetched.borrowerPhone, '555-8888');
      expect(fetched.isOut, isTrue);
    });

    test('lendItem convenience helper creates item, borrower, and loan in transaction', () async {
      final loan = await dbService.lendItem(
        itemName: 'Soldering Iron',
        category: ItemCategory.labGear,
        itemNotes: 'Variable temperature',
        borrowerName: 'Frankie',
        borrowerPhone: '555-4433',
        lentDate: DateTime(2026, 11, 24),
        expectedReturnDate: DateTime(2026, 12, 1),
        loanNotes: 'Needs it for weekend hackathon',
      );

      expect(loan.id, isNotNull);
      expect(loan.itemId, isPositive);
      expect(loan.borrowerId, isPositive);
      expect(loan.itemName, 'Soldering Iron');
      expect(loan.borrowerName, 'Frankie');
      expect(loan.notes, 'Needs it for weekend hackathon');

      // Verify item was created in DB
      final item = await dbService.getItem(loan.itemId);
      expect(item, isNotNull);
      expect(item!.name, 'Soldering Iron');

      // Verify borrower was created in DB
      final borrower = await dbService.getBorrower(loan.borrowerId);
      expect(borrower, isNotNull);
      expect(borrower!.name, 'Frankie');
      expect(borrower.activeLoansCount, 1);
    });

    test('markReturned updates status and returned date', () async {
      final loan = await dbService.lendItem(
        itemName: 'Physics Notes',
        category: ItemCategory.notes,
        borrowerName: 'George',
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
      );

      final returnDate = DateTime(2026, 11, 18);
      await dbService.markReturned(loan.id!, returnDate);

      final updated = await dbService.getLoan(loan.id!);
      expect(updated!.isReturned, isTrue);
      expect(updated.returnedDate, isNotNull);
      expect(Loan.isSameDay(updated.returnedDate!, returnDate), isTrue);

      final returnedLoans = await dbService.getReturnedLoans();
      expect(returnedLoans.any((l) => l.id == loan.id), isTrue);

      final activeLoans = await dbService.getActiveLoans();
      expect(activeLoans.any((l) => l.id == loan.id), isFalse);
    });

    test('delete loan removes record', () async {
      final loan = await dbService.lendItem(
        itemName: 'Headphones',
        category: ItemCategory.other,
        borrowerName: 'Hannah',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
      );

      expect(await dbService.getLoan(loan.id!), isNotNull);
      await dbService.deleteLoan(loan.id!);
      expect(await dbService.getLoan(loan.id!), isNull);
    });

    test('foreign key cascade delete removes loans when borrower is deleted', () async {
      final loan = await dbService.lendItem(
        itemName: 'Tablet',
        category: ItemCategory.other,
        borrowerName: 'Ian',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await dbService.deleteBorrower(loan.borrowerId);
      expect(await dbService.getLoan(loan.id!), isNull);
    });

    test('foreign key cascade delete removes loans when item is deleted', () async {
      final loan = await dbService.lendItem(
        itemName: 'Kindle',
        category: ItemCategory.books,
        borrowerName: 'Julia',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await dbService.deleteItem(loan.itemId);
      expect(await dbService.getLoan(loan.id!), isNull);
    });

    test('getLoansByBorrower and getLoansByItem', () async {
      final loan1 = await dbService.lendItem(
        itemName: 'Item A',
        category: ItemCategory.books,
        borrowerName: 'Kevin',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );
      await dbService.lendItem(
        itemName: 'Item B',
        category: ItemCategory.chargers,
        borrowerName: 'Kevin',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final kevinLoans = await dbService.getLoansByBorrower(loan1.borrowerId);
      expect(kevinLoans.length, 2);

      final itemALoans = await dbService.getLoansByItem(loan1.itemId);
      expect(itemALoans.length, 1);
      expect(itemALoans.first.id, loan1.id);
    });
  });

  group('DatabaseService - Settings & Full DB Operations', () {
    test('save and get settings', () async {
      const settings = AppSettings(
        defaultLoanPeriodDays: 25,
        reminderHour: 10,
        reminderMinute: 30,
        use24HourClock: true,
      );
      await dbService.saveSettings(settings);

      final loaded = await dbService.getSettings();
      expect(loaded, equals(settings));
    });

    test('exportAllData and restoreAllData', () async {
      await dbService.lendItem(
        itemName: 'Backup Test Book',
        category: ItemCategory.books,
        borrowerName: 'Leo',
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
      );

      final exported = await dbService.exportAllData();
      expect(exported['items'], isNotEmpty);
      expect(exported['borrowers'], isNotEmpty);
      expect(exported['loans'], isNotEmpty);

      // Clear all
      await dbService.clearAllData();
      expect(await dbService.getAllItems(), isEmpty);
      expect(await dbService.getAllBorrowers(), isEmpty);
      expect(await dbService.getAllLoans(), isEmpty);

      // Restore
      final restored = await dbService.restoreAllData(exported);
      expect(restored, isTrue);

      final restoredItems = await dbService.getAllItems();
      expect(restoredItems.length, 1);
      expect(restoredItems.first.name, 'Backup Test Book');
    });

    test('clearAllData completely empties database', () async {
      await dbService.lendItem(
        itemName: 'To Be Cleared',
        category: ItemCategory.other,
        borrowerName: 'Mia',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await dbService.clearAllData();
      expect(await dbService.getAllLoans(), isEmpty);
      expect(await dbService.getAllItems(), isEmpty);
      expect(await dbService.getAllBorrowers(), isEmpty);
    });

    test('getDashboardStats and getAppStats direct DB queries', () async {
      final now = DateTime(2026, 11, 24);
      final loan = await dbService.lendItem(
        itemName: 'Stats Book',
        category: ItemCategory.books,
        borrowerName: 'Noah',
        lentDate: now.subtract(const Duration(days: 5)),
        expectedReturnDate: now.add(const Duration(days: 2)),
      );

      final dash = await dbService.getDashboardStats(referenceDate: now);
      expect(dash.outNow, 1);
      expect(dash.dueSoon, 1);
      expect(dash.overdue, 0);
      expect(dash.nextItemDueBack?.id, loan.id);

      final stats = await dbService.getAppStats(referenceDate: now);
      expect(stats.totalUniqueItems, 1);
      expect(stats.totalUniqueBorrowers, 1);
      expect(stats.mostBorrowedItemName, 'Stats Book');
      expect(stats.mostFrequentBorrowerName, 'Noah');
    });
  });
}
