// [ShelfMate Dev Step 1/2]: Add widget tests for DashboardScreen metrics grid display
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/dashboard/dashboard_screen.dart';
import 'package:shelfmate/ui/screens/dashboard/widgets/next_due_card.dart';
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
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget', () {
    testWidgets('shows empty state when no items lent yet', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ShelfMate'), findsOneWidget);
      expect(find.text('Lend an Item'), findsOneWidget);
      expect(find.byType(NextDueCard), findsNothing);
    });

    testWidgets('shows metrics grid and NextDueCard when active loans exist', (tester) async {
      await appState.lendItem(
        itemName: 'Calculus Book',
        category: ItemCategory.books,
        borrowerName: 'Alice',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 2)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ShelfMate'), findsNothing);
      expect(find.byType(NextDueCard), findsOneWidget);
      expect(find.text('NEXT ITEM DUE BACK'), findsOneWidget);
      expect(find.text('Calculus Book'), findsWidgets);
      expect(find.text('Alice'), findsWidgets);

      expect(find.text('Out Now'), findsOneWidget);
      expect(find.text('Due Soon'), findsWidgets);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Total Lent Ever'), findsOneWidget);
    });

    testWidgets('tapping metric card updates selectedNavIndex', (tester) async {
      await appState.lendItem(
        itemName: 'USB Cable',
        category: ItemCategory.chargers,
        borrowerName: 'Bob',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 5)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Out Now'));
      await tester.pumpAndSettle();
      expect(appState.selectedNavIndex, 1);

      await tester.tap(find.text('Total Lent Ever'));
      await tester.pumpAndSettle();
      expect(appState.selectedNavIndex, 3);
    });

    testWidgets('NextDueCard displays all caught up when no loans due', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NextDueCard(loan: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('No items currently out or due back.'), findsOneWidget);
    });
  });
}
