import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/items/items_screen.dart';
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
        home: ItemsScreen(),
      ),
    );
  }

  group('ItemsScreen Widget', () {
    testWidgets('shows empty state when no items exist', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Out (0)'), findsOneWidget);
      expect(find.text('Returned (0)'), findsOneWidget);
      expect(find.text('No items currently out'), findsOneWidget);
    });

    testWidgets('displays active loan in Out tab', (tester) async {
      await appState.lendItem(
        itemName: 'Chemistry Notes',
        category: ItemCategory.notes,
        borrowerName: 'Sarah',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Out (1)'), findsOneWidget);
      expect(find.text('Chemistry Notes'), findsOneWidget);
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('Mark Returned'), findsOneWidget);
    });

    testWidgets('marks loan as returned and moves it to Returned tab', (tester) async {
      await appState.lendItem(
        itemName: 'Oscilloscope',
        category: ItemCategory.labGear,
        borrowerName: 'Frank',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 3)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Returned'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Returned'), findsOneWidget);
      await tester.tap(find.text('Confirm Return'));
      await tester.pumpAndSettle();

      expect(appState.activeLoans.isEmpty, isTrue);
      expect(appState.returnedLoans.length, 1);

      await tester.tap(find.text('Returned (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Oscilloscope'), findsOneWidget);
      expect(find.text('Lend Again'), findsOneWidget);
    });

    testWidgets('category filter chip filters items', (tester) async {
      await appState.lendItem(
        itemName: 'Book A',
        category: ItemCategory.books,
        borrowerName: 'Alice',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );
      await appState.lendItem(
        itemName: 'Charger B',
        category: ItemCategory.chargers,
        borrowerName: 'Bob',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Book A'), findsOneWidget);
      expect(find.text('Charger B'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Chargers'));
      await tester.pumpAndSettle();

      expect(find.text('Book A'), findsNothing);
      expect(find.text('Charger B'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Book A'), findsOneWidget);
      expect(find.text('Charger B'), findsOneWidget);
    });

    testWidgets('search query filters loans by name or borrower', (tester) async {
      await appState.lendItem(
        itemName: 'Microscope',
        category: ItemCategory.labGear,
        borrowerName: 'David',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );
      await appState.lendItem(
        itemName: 'Camera',
        category: ItemCategory.other,
        borrowerName: 'Emma',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'micro');
      await tester.pumpAndSettle();

      expect(find.text('Microscope'), findsOneWidget);
      expect(find.text('Camera'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      expect(find.text('Microscope'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
    });
  });
}
