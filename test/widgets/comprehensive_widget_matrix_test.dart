// [ShelfMate Dev Step 2/4]: Add matrix tests for MetricCard variants
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/ui/common/category_badge.dart';
import 'package:shelfmate/ui/common/confirm_dialog.dart';
import 'package:shelfmate/ui/common/empty_state_view.dart';
import 'package:shelfmate/ui/common/metric_card.dart';
import 'package:shelfmate/ui/common/status_badge.dart';
import 'package:shelfmate/ui/screens/dashboard/widgets/next_due_card.dart';

void main() {
  Widget testWrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('CategoryBadge Matrix (10 tests)', () {
    for (final cat in ItemCategory.values) {
      testWidgets('CategoryBadge for ${cat.displayName} with icon', (tester) async {
        await tester.pumpWidget(testWrap(CategoryBadge(category: cat, showIcon: true)));
        expect(find.text(cat.displayName), findsOneWidget);
        expect(find.byIcon(cat.icon), findsOneWidget);
      });

      testWidgets('CategoryBadge for ${cat.displayName} without icon', (tester) async {
        await tester.pumpWidget(testWrap(CategoryBadge(category: cat, showIcon: false)));
        expect(find.text(cat.displayName), findsOneWidget);
        expect(find.byIcon(cat.icon), findsNothing);
      });
    }
  });

  group('StatusBadge Matrix (12 tests)', () {
    for (final urgency in DueUrgency.values) {
      testWidgets('StatusBadge default label for ${urgency.label}', (tester) async {
        await tester.pumpWidget(testWrap(StatusBadge(urgency: urgency)));
        expect(find.text(urgency.label), findsOneWidget);
        expect(find.byIcon(urgency.icon), findsOneWidget);
      });

      testWidgets('StatusBadge custom label for ${urgency.label}', (tester) async {
        await tester.pumpWidget(testWrap(StatusBadge(urgency: urgency, customLabel: 'Custom ${urgency.label}')));
        expect(find.text('Custom ${urgency.label}'), findsOneWidget);
        expect(find.byIcon(urgency.icon), findsOneWidget);
      });
    }
  });

  group('MetricCard Matrix (8 tests)', () {
    final values = ['0', '1', '42', '999+'];
    for (final v in values) {
      testWidgets('MetricCard with value $v with subtitle', (tester) async {
        await tester.pumpWidget(testWrap(MetricCard(
          title: 'Title $v',
          value: v,
          icon: Icons.star,
          color: Colors.blue,
          subtitle: 'Subtitle $v',
        )));
        expect(find.text('Title $v'), findsOneWidget);
        expect(find.text(v), findsOneWidget);
        expect(find.text('Subtitle $v'), findsOneWidget);
      });

      testWidgets('MetricCard with value $v without subtitle', (tester) async {
        await tester.pumpWidget(testWrap(MetricCard(
          title: 'Title $v',
          value: v,
          icon: Icons.star,
          color: Colors.blue,
        )));
        expect(find.text('Title $v'), findsOneWidget);
        expect(find.text(v), findsOneWidget);
      });
    }
  });

  group('ConfirmDialog Matrix (5 tests)', () {
    final actions = ['Delete', 'Clear', 'Remove', 'Confirm', 'Reset'];
    for (final action in actions) {
      testWidgets('ConfirmDialog with action $action', (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await ConfirmDialog.show(
                      context: ctx,
                      title: 'Action $action?',
                      message: 'Are you sure you want to $action?',
                      confirmText: action,
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Action $action?'), findsOneWidget);
        expect(find.text('Are you sure you want to $action?'), findsOneWidget);
        expect(find.text(action), findsOneWidget);

        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(result, isTrue);
      });
    }
  });

  group('EmptyStateView Matrix (5 tests)', () {
    final titles = ['No Items', 'No Friends', 'No Stats', 'Empty Archive', 'Clean Slate'];
    for (final title in titles) {
      testWidgets('EmptyStateView with title $title', (tester) async {
        var clicked = false;
        await tester.pumpWidget(testWrap(EmptyStateView(
          icon: Icons.inbox,
          title: title,
          message: 'Message for $title',
          buttonText: 'Click $title',
          onButtonPressed: () => clicked = true,
        )));

        expect(find.text(title), findsOneWidget);
        expect(find.text('Message for $title'), findsOneWidget);
        expect(find.text('Click $title'), findsOneWidget);

        await tester.tap(find.text('Click $title'));
        await tester.pumpAndSettle();
        expect(clicked, isTrue);
      });
    }
  });

  group('NextDueCard Matrix (10 tests)', () {
    final categories = ItemCategory.values;
    for (var i = 0; i < categories.length; i++) {
      final cat = categories[i];
      testWidgets('NextDueCard with category ${cat.displayName} due soon', (tester) async {
        final loan = Loan(
          id: i + 1,
          itemId: i + 1,
          borrowerId: i + 1,
          lentDate: DateTime.now().subtract(const Duration(days: 3)),
          expectedReturnDate: DateTime.now().add(const Duration(days: 2)),
          status: LoanStatus.out,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          itemName: 'Item in ${cat.displayName}',
          itemCategory: cat,
          borrowerName: 'Friend $i',
        );

        await tester.pumpWidget(testWrap(NextDueCard(loan: loan)));
        await tester.pumpAndSettle();

        expect(find.text('NEXT ITEM DUE BACK'), findsOneWidget);
        expect(find.text('Item in ${cat.displayName}'), findsOneWidget);
        expect(find.text('Friend $i'), findsOneWidget);
      });

      testWidgets('NextDueCard with category ${cat.displayName} overdue', (tester) async {
        final loan = Loan(
          id: i + 10,
          itemId: i + 10,
          borrowerId: i + 10,
          lentDate: DateTime.now().subtract(const Duration(days: 10)),
          expectedReturnDate: DateTime.now().subtract(const Duration(days: 2)),
          status: LoanStatus.out,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          itemName: 'Overdue ${cat.displayName}',
          itemCategory: cat,
          borrowerName: 'Borrower $i',
        );

        await tester.pumpWidget(testWrap(NextDueCard(loan: loan)));
        await tester.pumpAndSettle();

        expect(find.text('NEXT ITEM DUE BACK'), findsOneWidget);
        expect(find.text('Overdue ${cat.displayName}'), findsOneWidget);
        expect(find.text('Borrower $i'), findsOneWidget);
      });
    }
  });
}
