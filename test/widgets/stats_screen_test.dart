import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/stats/stats_screen.dart';
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
        home: StatsScreen(),
      ),
    );
  }

  group('StatsScreen Widget', () {
    testWidgets('shows empty state when no loans recorded', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lending Statistics'), findsOneWidget);
      expect(find.text('No Stats Yet'), findsOneWidget);
      expect(find.text('Lend an Item'), findsOneWidget);
    });

    testWidgets('renders all stats cards when loans exist', (tester) async {
      await appState.lendItem(
        itemName: 'Organic Chemistry',
        category: ItemCategory.books,
        borrowerName: 'Hermione',
        lentDate: DateTime.now().subtract(const Duration(days: 10)),
        expectedReturnDate: DateTime.now().add(const Duration(days: 4)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ON-TIME RETURN RATE'), findsOneWidget);
      expect(find.text('Most-Borrowed Item'), findsOneWidget);
      expect(find.text('Organic Chemistry'), findsWidgets);
      expect(find.text('Most Frequent Borrower'), findsOneWidget);
      expect(find.text('Hermione'), findsWidgets);
      expect(find.text('Longest Outstanding Loan'), findsOneWidget);
      expect(find.text('Loans per Category'), findsOneWidget);
      expect(find.text('General Summary'), findsOneWidget);
    });
  });
}
