// [ShelfMate Dev Step 1/5]: Add query suite for complex filter combinations
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/database/database_helper.dart';
import 'package:shelfmate/database/database_service.dart';
import 'package:shelfmate/database/tables.dart';
import 'package:shelfmate/models/app_settings.dart';
import 'package:shelfmate/models/borrower.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DatabaseService dbService;

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
          await db.execute(Tables.createAppSettingsTable);
        },
      ),
    );
    dbService = DatabaseService(DatabaseHelper(db), db);
  });

  tearDown(() async {
    await db.close();
  });

  Borrower makeB(String name, [String? phone]) => Borrower(
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

  Item makeI(String name, ItemCategory cat, [String? notes]) => Item(
        name: name,
        category: cat,
        notes: notes,
        createdAt: DateTime.now(),
      );

  group('Exhaustive Database Tests - Batch Operations & Filtering', () {
    // 1-25: Batch inserts and category filtering
    for (final cat in ItemCategory.values) {
      test('insert 5 items for category ${cat.displayName} and verify persistence', () async {
        for (var i = 1; i <= 5; i++) {
          final id = await dbService.insertItem(makeI('${cat.displayName} Item $i', cat));
          final item = await dbService.getItem(id);
          expect(item?.name, '${cat.displayName} Item $i');
          expect(item?.category, cat);
        }
      });
    }

    // 26-35: Borrower name updates and joined loan integrity
    test('updating borrower name updates borrower_name on loan query', () async {
      final bId = await dbService.insertBorrower(makeB('Original Name', '111'));
      final loan = await dbService.lendItem(
        itemName: 'Textbook',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Original Name',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(loan.borrowerName, 'Original Name');

      // Update borrower
      final b = await dbService.getBorrower(bId);
      await dbService.updateBorrower(b!.copyWith(name: 'Updated Name'));

      final updatedLoan = await dbService.getLoan(loan.id!);
      expect(updatedLoan?.borrowerName, 'Updated Name');
    });

    test('updating borrower phone updates borrower_phone on loan query', () async {
      final bId = await dbService.insertBorrower(makeB('Phone User', '111'));
      final loan = await dbService.lendItem(
        itemName: 'Pen',
        category: ItemCategory.other,
        borrowerId: bId,
        borrowerName: 'Phone User',
        borrowerPhone: '111',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final b = await dbService.getBorrower(bId);
      await dbService.updateBorrower(b!.copyWith(phone: '999-999-9999'));

      final updatedLoan = await dbService.getLoan(loan.id!);
      expect(updatedLoan?.borrowerPhone, '999-999-9999');
    });

    test('updating item name updates item_name on loan query', () async {
      final iId = await dbService.insertItem(makeI('Initial Item Name', ItemCategory.chargers));
      final loan = await dbService.lendItem(
        itemId: iId,
        itemName: 'Initial Item Name',
        category: ItemCategory.chargers,
        borrowerName: 'Borrower',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final item = await dbService.getItem(iId);
      await dbService.updateItem(item!.copyWith(name: 'Brand New Item Name'));

      final updatedLoan = await dbService.getLoan(loan.id!);
      expect(updatedLoan?.itemName, 'Brand New Item Name');
    });

    test('updating item category updates item_category on loan query', () async {
      final iId = await dbService.insertItem(makeI('Gadget', ItemCategory.other));
      final loan = await dbService.lendItem(
        itemId: iId,
        itemName: 'Gadget',
        category: ItemCategory.other,
        borrowerName: 'Borrower',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final item = await dbService.getItem(iId);
      await dbService.updateItem(item!.copyWith(category: ItemCategory.labGear));

      final updatedLoan = await dbService.getLoan(loan.id!);
      expect(updatedLoan?.itemCategory, ItemCategory.labGear);
    });

    test('updating item notes updates item_notes on loan query', () async {
      final iId = await dbService.insertItem(makeI('Gadget', ItemCategory.other, 'Old notes'));
      final loan = await dbService.lendItem(
        itemId: iId,
        itemName: 'Gadget',
        category: ItemCategory.other,
        borrowerName: 'Borrower',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final item = await dbService.getItem(iId);
      await dbService.updateItem(item!.copyWith(notes: 'Updated detailed notes'));

      final updatedLoan = await dbService.getLoan(loan.id!);
      expect(updatedLoan?.itemNotes, 'Updated detailed notes');
    });

    // 36-50: Multiple loans across multiple borrowers
    for (var bIdx = 1; bIdx <= 15; bIdx++) {
      test('borrower $bIdx multi-loan isolation', () async {
        final bId = await dbService.insertBorrower(makeB('Friend $bIdx'));
        final loan1 = await dbService.lendItem(
          itemName: 'Book A $bIdx',
          category: ItemCategory.books,
          borrowerId: bId,
          borrowerName: 'Friend $bIdx',
          lentDate: DateTime.now(),
          expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
        );
        final loan2 = await dbService.lendItem(
          itemName: 'Book B $bIdx',
          category: ItemCategory.books,
          borrowerId: bId,
          borrowerName: 'Friend $bIdx',
          lentDate: DateTime.now(),
          expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
        );

        final borrowerLoans = await dbService.getLoansByBorrower(bId);
        expect(borrowerLoans.length, 2);
        expect(borrowerLoans.map((l) => l.id), containsAll([loan1.id, loan2.id]));

        final bObj = await dbService.getBorrower(bId);
        expect(bObj?.activeLoansCount, 2);
        expect(bObj?.totalLoansCount, 2);
      });
    }

    // 51-65: Granular AppSettings tests
    final settingsCombinations = [
      const AppSettings(defaultLoanPeriodDays: 1, reminderHour: 0, reminderMinute: 0, use24HourClock: false),
      const AppSettings(defaultLoanPeriodDays: 2, reminderHour: 6, reminderMinute: 15, use24HourClock: true),
      const AppSettings(defaultLoanPeriodDays: 7, reminderHour: 9, reminderMinute: 30, use24HourClock: false),
      const AppSettings(defaultLoanPeriodDays: 14, reminderHour: 12, reminderMinute: 0, use24HourClock: true),
      const AppSettings(defaultLoanPeriodDays: 21, reminderHour: 15, reminderMinute: 45, use24HourClock: false),
      const AppSettings(defaultLoanPeriodDays: 30, reminderHour: 18, reminderMinute: 0, use24HourClock: true),
      const AppSettings(defaultLoanPeriodDays: 60, reminderHour: 20, reminderMinute: 30, use24HourClock: false),
      const AppSettings(defaultLoanPeriodDays: 90, reminderHour: 22, reminderMinute: 15, use24HourClock: true),
      const AppSettings(defaultLoanPeriodDays: 180, reminderHour: 23, reminderMinute: 59, use24HourClock: false),
      const AppSettings(defaultLoanPeriodDays: 365, reminderHour: 8, reminderMinute: 5, use24HourClock: true),
    ];

    for (var i = 0; i < settingsCombinations.length; i++) {
      test('settings combination $i saves and reloads accurately', () async {
        final expected = settingsCombinations[i];
        await dbService.saveSettings(expected);
        final loaded = await dbService.getSettings();

        expect(loaded.defaultLoanPeriodDays, expected.defaultLoanPeriodDays);
        expect(loaded.reminderHour, expected.reminderHour);
        expect(loaded.reminderMinute, expected.reminderMinute);
        expect(loaded.use24HourClock, expected.use24HourClock);
      });
    }

    // 66-80: Delete loan isolation
    for (var delIdx = 1; delIdx <= 15; delIdx++) {
      test('deleting loan $delIdx does not affect remaining loans', () async {
        final bId = await dbService.insertBorrower(makeB('Keeper $delIdx'));
        final l1 = await dbService.lendItem(
          itemName: 'Keep Item $delIdx',
          category: ItemCategory.books,
          borrowerId: bId,
          borrowerName: 'Keeper $delIdx',
          lentDate: DateTime.now(),
          expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
        );
        final l2 = await dbService.lendItem(
          itemName: 'Delete Item $delIdx',
          category: ItemCategory.notes,
          borrowerId: bId,
          borrowerName: 'Keeper $delIdx',
          lentDate: DateTime.now(),
          expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
        );

        expect((await dbService.getLoansByBorrower(bId)).length, 2);

        await dbService.deleteLoan(l2.id!);

        final remaining = await dbService.getLoansByBorrower(bId);
        expect(remaining.length, 1);
        expect(remaining.first.id, l1.id);
        expect(await dbService.getLoan(l2.id!), isNull);
      });
    }
  });
}
