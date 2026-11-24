import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/notification_service.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/screens/borrowers/widgets/add_borrower_dialog.dart';
import 'package:shelfmate/ui/screens/items/lend_item_sheet.dart';
import 'package:shelfmate/ui/screens/items/mark_returned_dialog.dart';
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

  Widget buildWrapper(Widget child) {
    return AppStateProvider(
      appState: appState,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('LendItemSheet Widget Interactions', () {
    testWidgets('LendItemSheet displays required input fields', (tester) async {
      await tester.pumpWidget(buildWrapper(const LendItemSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Lend an Item'), findsOneWidget);
      expect(find.text('Item Name *'), findsOneWidget);
      expect(find.text("Friend's Name *"), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Item Note (optional)'), findsOneWidget);
      expect(find.text('Loan Note (optional)'), findsOneWidget);
      expect(find.text('Lend Item Now'), findsOneWidget);
    });

    testWidgets('LendItemSheet validation fails when submitting empty fields', (tester) async {
      await tester.pumpWidget(buildWrapper(const LendItemSheet()));
      await tester.pumpAndSettle();

      // Scroll to button & tap submit without filling fields
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Lend Item Now'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Lend Item Now'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the item name'), findsOneWidget);
      expect(find.text("Please enter the friend's name"), findsOneWidget);
      expect(appState.activeLoans, isEmpty);
    });

    testWidgets('LendItemSheet successfully creates loan when valid inputs provided', (tester) async {
      await tester.pumpWidget(buildWrapper(const LendItemSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Item Name *'), 'Calculus Textbook');
      await tester.enterText(find.widgetWithText(TextFormField, "Friend's Name *"), 'Hermione');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Lend Item Now'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Lend Item Now'));
      await tester.pumpAndSettle();

      expect(appState.activeLoans.length, 1);
      expect(appState.activeLoans.first.itemName, 'Calculus Textbook');
      expect(appState.activeLoans.first.borrowerName, 'Hermione');
    });

    testWidgets('LendItemSheet pre-fills item and borrower when supplied as props', (tester) async {
      final initialLoan = await fakeDb.lendItem(
        itemName: 'Pre-filled Book',
        category: ItemCategory.books,
        borrowerName: 'Existing Borrower',
        lentDate: DateTime.now(),
        expectedReturnDate: DateTime.now().add(const Duration(days: 7)),
      );
      final itemObj = await fakeDb.getItem(initialLoan.itemId);
      final borrowerObj = await fakeDb.getBorrower(initialLoan.borrowerId);

      await tester.pumpWidget(buildWrapper(LendItemSheet(
        preselectedItem: itemObj,
        preselectedBorrower: borrowerObj,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Pre-filled Book'), findsOneWidget);
      expect(find.text('Existing Borrower'), findsOneWidget);
    });
  });

  group('AddBorrowerDialog Widget Interactions', () {
    testWidgets('displays title and form fields', (tester) async {
      await tester.pumpWidget(buildWrapper(const AddBorrowerDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsWidgets);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Phone (optional)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('validation error when borrower name is empty', (tester) async {
      await tester.pumpWidget(buildWrapper(const AddBorrowerDialog()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('submitting valid borrower name adds borrower to state', (tester) async {
      await tester.pumpWidget(buildWrapper(const AddBorrowerDialog()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Name *'), 'Ron Weasley');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), '555-1234');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pumpAndSettle();

      expect(appState.borrowers.length, 1);
      expect(appState.borrowers.first.name, 'Ron Weasley');
      expect(appState.borrowers.first.phone, '555-1234');
    });
  });

  group('MarkReturnedDialog Widget Interactions', () {
    testWidgets('displays item name, borrower name, and confirm button', (tester) async {
      final loan = await fakeDb.lendItem(
        itemName: 'USB-C Cable',
        category: ItemCategory.chargers,
        borrowerName: 'Harry',
        lentDate: DateTime.now().subtract(const Duration(days: 3)),
        expectedReturnDate: DateTime.now().add(const Duration(days: 4)),
      );

      await tester.pumpWidget(buildWrapper(MarkReturnedDialog(loan: loan)));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Returned'), findsOneWidget);
      expect(find.text('Confirm Return'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Item: USB-C Cable'), findsOneWidget);
      expect(find.text('Borrower: Harry'), findsOneWidget);
    });

    testWidgets('confirming return returns the picked date on pop', (tester) async {
      final loan = await fakeDb.lendItem(
        itemName: 'USB-C Cable',
        category: ItemCategory.chargers,
        borrowerName: 'Harry',
        lentDate: DateTime.now().subtract(const Duration(days: 3)),
        expectedReturnDate: DateTime.now().add(const Duration(days: 4)),
      );

      DateTime? returnedDate;
      await tester.pumpWidget(
        AppStateProvider(
          appState: appState,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedDate = await MarkReturnedDialog.show(ctx, loan);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Returned'), findsOneWidget);
      await tester.tap(find.text('Confirm Return'));
      await tester.pumpAndSettle();

      expect(returnedDate, isNotNull);
    });
  });
}
