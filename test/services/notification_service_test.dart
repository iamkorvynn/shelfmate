import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late MockNotificationService mockService;
    final now = DateTime.now();

    setUp(() {
      mockService = MockNotificationService();
    });

    test('initialize sets isInitialized to true', () async {
      expect(mockService.isInitialized, isFalse);
      await mockService.initialize();
      expect(mockService.isInitialized, isTrue);
    });

    test('cancelAll clears scheduled and shown notifications', () async {
      await mockService.showNotification(id: 1, title: 'Title', body: 'Body');
      expect(mockService.shownNotifications.length, 1);
      await mockService.cancelAll();
      expect(mockService.shownNotifications, isEmpty);
      expect(mockService.scheduledNotifications, isEmpty);
    });

    test('showNotification records notification details', () async {
      await mockService.showNotification(
        id: 42,
        title: 'Return Reminder',
        body: 'Please return the item.',
      );
      expect(mockService.shownNotifications.length, 1);
      expect(mockService.shownNotifications.first['id'], 42);
      expect(mockService.shownNotifications.first['title'], 'Return Reminder');
      expect(mockService.shownNotifications.first['body'], 'Please return the item.');
    });

    test('scheduleReminders generates notifications for overdue, today, and tomorrow loans', () async {
      final loans = [
        // Overdue
        Loan(
          itemId: 1,
          borrowerId: 1,
          itemName: 'Book A',
          borrowerName: 'Alice',
          status: LoanStatus.out,
          lentDate: now.subtract(const Duration(days: 10)),
          expectedReturnDate: now.subtract(const Duration(days: 2)),
          createdAt: now,
        ),
        // Due today
        Loan(
          itemId: 2,
          borrowerId: 2,
          itemName: 'Charger B',
          borrowerName: 'Bob',
          status: LoanStatus.out,
          lentDate: now.subtract(const Duration(days: 5)),
          expectedReturnDate: DateTime(now.year, now.month, now.day, 18, 0),
          createdAt: now,
        ),
        // Due tomorrow
        Loan(
          itemId: 3,
          borrowerId: 3,
          itemName: 'Notes C',
          borrowerName: 'Charlie',
          status: LoanStatus.out,
          lentDate: now.subtract(const Duration(days: 5)),
          expectedReturnDate: DateTime(now.year, now.month, now.day + 1, 10, 0),
          createdAt: now,
        ),
        // Due in 5 days (not scheduled as urgent)
        Loan(
          itemId: 4,
          borrowerId: 4,
          itemName: 'Tool D',
          borrowerName: 'David',
          status: LoanStatus.out,
          lentDate: now,
          expectedReturnDate: now.add(const Duration(days: 5)),
          createdAt: now,
        ),
        // Already returned (no reminder)
        Loan(
          itemId: 5,
          borrowerId: 5,
          itemName: 'Gear E',
          borrowerName: 'Eva',
          status: LoanStatus.returned,
          lentDate: now.subtract(const Duration(days: 10)),
          expectedReturnDate: now.subtract(const Duration(days: 2)),
          returnedDate: now.subtract(const Duration(days: 1)),
          createdAt: now,
        ),
      ];

      await mockService.scheduleReminders(loans, const TimeOfDay(hour: 9, minute: 0));

      expect(mockService.scheduledNotifications.length, 3);
      final types = mockService.scheduledNotifications.map((n) => n['type']).toList();
      expect(types, contains('overdue'));
      expect(types, contains('today'));
      expect(types, contains('tomorrow'));
    });
  });
}
