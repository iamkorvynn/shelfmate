// [ShelfMate Dev Step 1/4]: Add widget tests for CategoryBadge rendering across categories
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/ui/common/category_badge.dart';
import 'package:shelfmate/ui/common/confirm_dialog.dart';
import 'package:shelfmate/ui/common/empty_state_view.dart';
import 'package:shelfmate/ui/common/metric_card.dart';
import 'package:shelfmate/ui/common/status_badge.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('CategoryBadge Widget', () {
    testWidgets('renders all category badges with display names', (tester) async {
      for (final cat in ItemCategory.values) {
        await tester.pumpWidget(buildTestableWidget(CategoryBadge(category: cat)));
        expect(find.text(cat.displayName), findsOneWidget);
      }
    });

    testWidgets('respects showIcon parameter', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CategoryBadge(category: ItemCategory.books, showIcon: false),
      ));
      expect(find.text('Books'), findsOneWidget);
      expect(find.byIcon(ItemCategory.books.icon), findsNothing);

      await tester.pumpWidget(buildTestableWidget(
        const CategoryBadge(category: ItemCategory.books, showIcon: true),
      ));
      expect(find.byIcon(ItemCategory.books.icon), findsOneWidget);
    });
  });

  group('StatusBadge Widget', () {
    testWidgets('renders all urgency statuses', (tester) async {
      for (final urgency in DueUrgency.values) {
        await tester.pumpWidget(buildTestableWidget(StatusBadge(urgency: urgency)));
        expect(find.text(urgency.label), findsOneWidget);
        expect(find.byIcon(urgency.icon), findsOneWidget);
      }
    });

    testWidgets('renders custom label when provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const StatusBadge(urgency: DueUrgency.overdue, customLabel: '3 days overdue'),
      ));
      expect(find.text('3 days overdue'), findsOneWidget);
      expect(find.byIcon(DueUrgency.overdue.icon), findsOneWidget);
    });
  });

  group('MetricCard Widget', () {
    testWidgets('renders title, value, icon, and optional subtitle', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MetricCard(
          title: 'Active Loans',
          value: '12',
          icon: Icons.outbox,
          color: Colors.blue,
          subtitle: 'With friends',
        ),
      ));

      expect(find.text('Active Loans'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('With friends'), findsOneWidget);
      expect(find.byIcon(Icons.outbox), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(
        MetricCard(
          title: 'Tappable',
          value: '5',
          icon: Icons.star,
          color: Colors.amber,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(MetricCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('EmptyStateView Widget', () {
    testWidgets('renders title, message, and icon', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const EmptyStateView(
          icon: Icons.inbox,
          title: 'No Items',
          message: 'Your list is empty right now.',
        ),
      ));

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Your list is empty right now.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders action button and triggers callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildTestableWidget(
        EmptyStateView(
          icon: Icons.inbox,
          title: 'Empty',
          message: 'Nothing here.',
          buttonText: 'Add Something',
          onButtonPressed: () => pressed = true,
        ),
      ));

      expect(find.text('Add Something'), findsOneWidget);
      await tester.tap(find.text('Add Something'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('ConfirmDialog Widget', () {
    testWidgets('clicking cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context: context,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('clicking confirm returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context: context,
                  title: 'Delete Item',
                  message: 'Confirm delete?',
                  confirmText: 'Delete',
                  isDestructive: true,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
