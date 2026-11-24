// [ShelfMate Dev Step 1/2]: Add widget tests for SettingsScreen preference controls
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/settings/settings_screen.dart';
import 'package:shelfmate/ui/screens/settings/widgets/data_dialogs.dart';
import '../helpers/fake_database_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late AppState appState;

  setUp(() async {
    fakeDb = FakeDatabaseService();
    appState = AppState(
      databaseService: fakeDb,
      notificationService: MockNotificationService(),
    );
    await appState.initialize();
  });

  Widget createWidget() {
    return AppStateProvider(
      appState: appState,
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Widget', () {
    testWidgets('renders all settings options and sections', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('LOAN PREFERENCES'), findsOneWidget);
      expect(find.text('Default Loan Period'), findsOneWidget);
      expect(find.text('Daily Reminder Time'), findsOneWidget);
      expect(find.text('24-Hour Clock'), findsOneWidget);
      expect(find.text('DATA & BACKUP'), findsOneWidget);
      expect(find.text('Export Data (CSV)'), findsOneWidget);
      expect(find.text('Backup Data (JSON)'), findsOneWidget);
      expect(find.text('Restore Data (JSON)'), findsOneWidget);
      expect(find.text('Clear All Data'), findsOneWidget);
      expect(find.text('ABOUT SHELFMATE'), findsOneWidget);
    });

    testWidgets('toggling 24-hour clock updates settings in state', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(appState.settings.use24HourClock, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(appState.settings.use24HourClock, isTrue);
    });

    testWidgets('tapping Export Data (CSV) opens CsvExportDialog', (tester) async {
      await appState.lendItem(
        itemName: 'Sample Book',
        category: ItemCategory.books,
        borrowerName: 'Sam',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Data (CSV)'));
      await tester.pumpAndSettle();

      expect(find.byType(CsvExportDialog), findsOneWidget);
      expect(find.text('Copy CSV'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(CsvExportDialog), findsNothing);
    });

    testWidgets('tapping Backup Data (JSON) opens JsonBackupDialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Backup Data (JSON)'));
      await tester.pumpAndSettle();

      expect(find.byType(JsonBackupDialog), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(JsonBackupDialog), findsNothing);
    });

    testWidgets('tapping Restore Data (JSON) opens JsonRestoreDialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Restore Data (JSON)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore Data (JSON)'));
      await tester.pumpAndSettle();

      expect(find.byType(JsonRestoreDialog), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(JsonRestoreDialog), findsNothing);
    });

    testWidgets('tapping Clear All Data opens confirmation dialog', (tester) async {
      await appState.lendItem(
        itemName: 'Book To Clear',
        category: ItemCategory.books,
        borrowerName: 'Sam',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Clear All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All Data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear All Data?'), findsOneWidget);
      expect(find.text('Delete Everything'), findsOneWidget);

      await tester.tap(find.text('Delete Everything'));
      await tester.pumpAndSettle();

      expect(appState.activeLoans, isEmpty);
      expect(appState.items, isEmpty);
      expect(appState.borrowers, isEmpty);
    });
  });
}
