import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/main.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/borrowers/borrowers_screen.dart';
import 'package:shelfmate/ui/screens/dashboard/dashboard_screen.dart';
import 'package:shelfmate/ui/screens/items/items_screen.dart';
import 'package:shelfmate/ui/screens/settings/settings_screen.dart';
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

  testWidgets('ShelfMateApp initializes and displays MainScreen with NavigationBar', (tester) async {
    await tester.pumpWidget(ShelfMateApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Items'), findsWidgets);
    expect(find.text('Borrowers'), findsWidgets);
    expect(find.text('Stats'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(ItemsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(BorrowersScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(StatsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(SettingsScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('NavigationBar navigation switches active tab index', (tester) async {
    await tester.pumpWidget(ShelfMateApp(appState: appState));
    await tester.pumpAndSettle();

    expect(appState.selectedNavIndex, 0);

    // Switch to Items tab
    await tester.tap(find.text('Items').first);
    await tester.pumpAndSettle();
    expect(appState.selectedNavIndex, 1);

    // Switch to Borrowers tab
    await tester.tap(find.text('Borrowers').first);
    await tester.pumpAndSettle();
    expect(appState.selectedNavIndex, 2);

    // Switch to Stats tab
    await tester.tap(find.text('Stats').first);
    await tester.pumpAndSettle();
    expect(appState.selectedNavIndex, 3);

    // Switch to Settings tab
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(appState.selectedNavIndex, 4);

    // Switch back to Dashboard
    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();
    expect(appState.selectedNavIndex, 0);
  });
}
