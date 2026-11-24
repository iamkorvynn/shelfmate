// [ShelfMate Dev Step 3/4]: Add tests for AppState borrower addition and lookup
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/database/database_helper.dart';
import 'package:shelfmate/database/database_service.dart';
import 'package:shelfmate/database/tables.dart';
import 'package:shelfmate/models/app_settings.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseService dbService;
  late MockNotificationService mockNotifications;
  late AppState appState;

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
          await db.execute(Tables.createAppSettingsTable);
        },
      ),
    );
    dbService = DatabaseService(DatabaseHelper(db));
    mockNotifications = MockNotificationService();
    appState = AppState(
      databaseService: dbService,
      notificationService: mockNotifications,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AppState', () {
    test('initial state is loading and starts empty', () {
      expect(appState.isLoading, isTrue);
      expect(appState.activeLoans, isEmpty);
      expect(appState.returnedLoans, isEmpty);
      expect(appState.borrowers, isEmpty);
      expect(appState.items, isEmpty);
      expect(appState.selectedNavIndex, 0);
    });

    test('initialize loads empty database and completes loading', () async {
      await appState.initialize();
      expect(appState.isLoading, isFalse);
      expect(mockNotifications.isInitialized, isTrue);
      expect(appState.borrowers, isEmpty);
      expect(appState.items, isEmpty);
      expect(appState.activeLoans, isEmpty);
      expect(appState.dashboardStats.totalLentEver, 0);
    });

    test('setNavIndex changes index and notifies', () async {
      await appState.initialize();
      var notified = false;
      appState.addListener(() => notified = true);

      appState.setNavIndex(2);
      expect(appState.selectedNavIndex, 2);
      expect(notified, isTrue);

      // Same index should not notify
      notified = false;
      appState.setNavIndex(2);
      expect(notified, isFalse);
    });

    test('lendItem adds active loan and updates dashboard stats', () async {
      await appState.initialize();
      final loan = await appState.lendItem(
        itemName: 'Calculus',
        category: ItemCategory.books,
        borrowerName: 'Sarah',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(loan.id, isNotNull);
      expect(appState.activeLoans.length, 1);
      expect(appState.borrowers.length, 1);
      expect(appState.items.length, 1);
      expect(appState.dashboardStats.outNow, 1);
      expect(appState.dashboardStats.totalLentEver, 1);
      expect(appState.dashboardStats.nextItemDueBack?.id, loan.id);
    });

    test('markReturned moves loan from active to returned', () async {
      await appState.initialize();
      final loan = await appState.lendItem(
        itemName: 'USB Cable',
        category: ItemCategory.chargers,
        borrowerName: 'Mike',
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 17),
      );

      expect(appState.activeLoans.length, 1);
      expect(appState.returnedLoans.length, 0);

      await appState.markReturned(loan.id!, DateTime(2026, 11, 16));

      expect(appState.activeLoans.length, 0);
      expect(appState.returnedLoans.length, 1);
      expect(appState.returnedLoans.first.isReturned, isTrue);
      expect(appState.dashboardStats.outNow, 0);
      expect(appState.dashboardStats.totalLentEver, 1);
    });

    test('deleteLoan removes loan completely', () async {
      await appState.initialize();
      final loan = await appState.lendItem(
        itemName: 'Lab Coat',
        category: ItemCategory.labGear,
        borrowerName: 'Alex',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect(appState.activeLoans.length, 1);
      await appState.deleteLoan(loan.id!);
      expect(appState.activeLoans.length, 0);
      expect(appState.dashboardStats.totalLentEver, 0);
    });

    test('borrower CRUD operations', () async {
      await appState.initialize();
      final bId = await appState.addBorrower('Diana Prince', '555-0101');
      expect(appState.borrowers.length, 1);
      expect(appState.borrowers.first.name, 'Diana Prince');

      final borrower = appState.borrowers.first;
      await appState.updateBorrower(borrower.copyWith(name: 'Diana P.'));
      expect(appState.borrowers.first.name, 'Diana P.');

      await appState.deleteBorrower(bId);
      expect(appState.borrowers.length, 0);
    });

    test('addItem creates an item record', () async {
      await appState.initialize();
      final itemId = await appState.addItem('Raspberry Pi', ItemCategory.labGear, 'Model 4B');
      expect(itemId, isPositive);
      expect(appState.items.length, 1);
      expect(appState.items.first.name, 'Raspberry Pi');
    });

    test('updateSettings updates state and reschedules notifications', () async {
      await appState.initialize();
      const newSettings = AppSettings(defaultLoanPeriodDays: 30, reminderHour: 8);
      await appState.updateSettings(newSettings);
      expect(appState.settings.defaultLoanPeriodDays, 30);
      expect(appState.settings.reminderHour, 8);
    });

    test('exportCsv returns CSV text', () async {
      await appState.initialize();
      await appState.lendItem(
        itemName: 'Textbook',
        category: ItemCategory.books,
        borrowerName: 'Emma',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      final csv = await appState.exportCsv();
      expect(csv, contains('Textbook'));
      expect(csv, contains('Emma'));
    });

    test('exportBackupJson and restoreBackupJson', () async {
      await appState.initialize();
      await appState.lendItem(
        itemName: 'JSON Item',
        category: ItemCategory.notes,
        borrowerName: 'Lucas',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
      );

      final jsonBackup = await appState.exportBackupJson();
      expect(jsonBackup, contains('JSON Item'));
      expect(jsonBackup, contains('Lucas'));

      await appState.clearAllData();
      expect(appState.items, isEmpty);
      expect(appState.borrowers, isEmpty);
      expect(appState.activeLoans, isEmpty);

      final restored = await appState.restoreBackupJson(jsonBackup);
      expect(restored, isTrue);
      expect(appState.items.length, 1);
      expect(appState.borrowers.length, 1);
      expect(appState.activeLoans.length, 1);
    });

    test('clearAllData wipes database and resets', () async {
      await appState.initialize();
      await appState.lendItem(
        itemName: 'To Clear',
        category: ItemCategory.other,
        borrowerName: 'Nobody',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(appState.activeLoans.isNotEmpty, isTrue);
      await appState.clearAllData();
      expect(appState.activeLoans, isEmpty);
      expect(appState.returnedLoans, isEmpty);
      expect(appState.items, isEmpty);
      expect(appState.borrowers, isEmpty);
      expect(appState.dashboardStats.totalLentEver, 0);
    });
  });
}
