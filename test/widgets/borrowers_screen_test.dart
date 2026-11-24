// [ShelfMate Dev Step 1/2]: Add widget tests for BorrowersScreen friend list rendering
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/borrowers/borrower_detail_screen.dart';
import 'package:shelfmate/ui/screens/borrowers/borrowers_screen.dart';
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
        home: BorrowersScreen(),
      ),
    );
  }

  group('BorrowersScreen Widget', () {
    testWidgets('shows empty state when no friends exist', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Friends & Borrowers'), findsOneWidget);
      expect(find.text('No friends added yet'), findsOneWidget);
      expect(find.text('Add Friend'), findsOneWidget);
    });

    testWidgets('adds friend via Add Friend dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsWidgets);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name *'), 'Peter Parker');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), '555-0199');

      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend').last);
      await tester.pumpAndSettle();

      expect(find.text('Peter Parker'), findsOneWidget);
      expect(find.text('555-0199'), findsOneWidget);
      expect(find.text('0 Out'), findsOneWidget);
    });

    testWidgets('navigates to BorrowerDetailScreen on tap', (tester) async {
      final bId = await appState.addBorrower('Bruce Wayne', '555-0001');
      await appState.lendItem(
        itemName: 'Batmobile Manual',
        category: ItemCategory.books,
        borrowerId: bId,
        borrowerName: 'Bruce Wayne',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bruce Wayne'), findsOneWidget);
      await tester.tap(find.text('Bruce Wayne'));
      await tester.pumpAndSettle();

      expect(find.byType(BorrowerDetailScreen), findsOneWidget);
      expect(find.text('Currently Borrowed (1)'), findsOneWidget);
      expect(find.text('Batmobile Manual'), findsOneWidget);
      expect(find.text('Lend to Friend'), findsOneWidget);
    });
  });
}
