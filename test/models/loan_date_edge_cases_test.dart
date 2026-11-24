import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';

void main() {
  Loan createLoan({
    int id = 1,
    int itemId = 1,
    int borrowerId = 1,
    required DateTime lentDate,
    required DateTime expectedReturnDate,
    DateTime? returnedDate,
    LoanStatus status = LoanStatus.out,
    String? notes,
    String itemName = 'Book',
    ItemCategory category = ItemCategory.books,
    String borrowerName = 'Alice',
  }) {
    return Loan(
      id: id,
      itemId: itemId,
      borrowerId: borrowerId,
      lentDate: lentDate,
      expectedReturnDate: expectedReturnDate,
      returnedDate: returnedDate,
      status: status,
      notes: notes,
      createdAt: lentDate,
      itemName: itemName,
      itemCategory: category,
      borrowerName: borrowerName,
    );
  }

  group('Loan Date & Urgency Edge Cases', () {
    // 1-15: Same Day and Time-of-Day Boundaries
    test('expected return date at 00:00:00 on reference date is due today and not overdue', () {
      final now = DateTime(2026, 11, 24, 14, 30);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 24, 0, 0, 0),
      );
      expect(loan.isDueToday(now), isTrue);
      expect(loan.isOverdue(now), isFalse);
      expect(loan.getUrgency(now), DueUrgency.dueToday);
    });

    test('expected return date at 23:59:59 on reference date is due today and not overdue', () {
      final now = DateTime(2026, 11, 24, 8, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 24, 23, 59, 59),
      );
      expect(loan.isDueToday(now), isTrue);
      expect(loan.isOverdue(now), isFalse);
      expect(loan.getUrgency(now), DueUrgency.dueToday);
    });

    test('expected return date yesterday at 23:59:59 is overdue today at 00:00:01', () {
      final now = DateTime(2026, 11, 24, 0, 0, 1);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 23, 23, 59, 59),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 1);
      expect(loan.getUrgency(now), DueUrgency.overdue);
    });

    test('expected return date tomorrow at 00:00:00 is due tomorrow today at 23:59:59', () {
      final now = DateTime(2026, 11, 24, 23, 59, 59);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 25, 0, 0, 0),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.getUrgency(now), DueUrgency.dueTomorrow);
      expect(loan.daysRemaining(now), 1);
    });

    test('expected return date in 2 days is due soon', () {
      final now = DateTime(2026, 11, 24, 12, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 26, 12, 0),
      );
      expect(loan.isDueSoon(now), isTrue);
      expect(loan.getUrgency(now), DueUrgency.dueSoon);
      expect(loan.daysRemaining(now), 2);
    });

    test('expected return date in 3 days is onSchedule', () {
      final now = DateTime(2026, 11, 24, 12, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 27, 12, 0),
      );
      expect(loan.isDueSoon(now), isFalse);
      expect(loan.getUrgency(now), DueUrgency.onSchedule);
      expect(loan.daysRemaining(now), 3);
    });

    test('expected return date in 100 days is onSchedule', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 24),
        expectedReturnDate: DateTime(2027, 3, 4),
      );
      expect(loan.getUrgency(now), DueUrgency.onSchedule);
      expect(loan.daysRemaining(now), 100);
    });

    test('overdue by exactly 1 day', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 23),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 1);
    });

    test('overdue by 15 days', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 9),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 15);
    });

    test('overdue by 365 days', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2025, 11, 1),
        expectedReturnDate: DateTime(2025, 11, 24),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 365);
    });

    // 11-25: Returned Loans
    test('returned loan is never overdue even if returned past expected date', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 15),
        status: LoanStatus.returned,
      );
      expect(loan.isOverdue(now), isFalse);
      expect(loan.isDueToday(now), isFalse);
      expect(loan.isDueTomorrow(now), isFalse);
      expect(loan.isDueSoon(now), isFalse);
      expect(loan.getUrgency(now), DueUrgency.returned);
    });

    test('returned loan returned on time reports wasReturnedOnTime true', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 10),
        status: LoanStatus.returned,
      );
      expect(loan.wasReturnedOnTime, isTrue);
    });

    test('returned loan returned early reports wasReturnedOnTime true', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 5),
        status: LoanStatus.returned,
      );
      expect(loan.wasReturnedOnTime, isTrue);
    });

    test('returned loan returned 1 day late reports wasReturnedOnTime false', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 11),
        status: LoanStatus.returned,
      );
      expect(loan.wasReturnedOnTime, isFalse);
    });

    test('returned loan returned 30 days late reports wasReturnedOnTime false', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 10, 1),
        expectedReturnDate: DateTime(2026, 10, 15),
        returnedDate: DateTime(2026, 11, 14),
        status: LoanStatus.returned,
      );
      expect(loan.wasReturnedOnTime, isFalse);
    });

    test('active loan reports wasReturnedOnTime null', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        status: LoanStatus.out,
      );
      expect(loan.wasReturnedOnTime, isNull);
    });

    test('totalDaysOut for returned loan uses returnedDate', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 8),
        status: LoanStatus.returned,
      );
      expect(loan.totalDaysOut(), 7);
    });

    test('totalDaysOut for same day returned loan is at least 1 day', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1, 10, 0),
        expectedReturnDate: DateTime(2026, 11, 5),
        returnedDate: DateTime(2026, 11, 1, 18, 0),
        status: LoanStatus.returned,
      );
      expect(loan.totalDaysOut(), 1);
    });

    test('totalDaysOut for active loan uses referenceDate', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
        status: LoanStatus.out,
      );
      expect(loan.totalDaysOut(DateTime(2026, 11, 24)), 14);
    });

    test('daysOverdue returns 0 for non-overdue active loan', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 25),
      );
      expect(loan.daysOverdue(now), 0);
    });

    test('daysRemaining returns negative days for overdue loan', () {
      final now = DateTime(2026, 11, 24);
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
      );
      expect(loan.daysRemaining(now), -4);
    });

    // 26-45: Leap Years & Month Transitions
    test('leap year Feb 28 to Feb 29 2024 is due tomorrow on Feb 28', () {
      final now = DateTime(2024, 2, 28, 12, 0);
      final loan = createLoan(
        lentDate: DateTime(2024, 2, 20),
        expectedReturnDate: DateTime(2024, 2, 29),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.daysRemaining(now), 1);
    });

    test('leap year Feb 29 to March 1 2024 is due tomorrow on Feb 29', () {
      final now = DateTime(2024, 2, 29, 12, 0);
      final loan = createLoan(
        lentDate: DateTime(2024, 2, 25),
        expectedReturnDate: DateTime(2024, 3, 1),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.daysRemaining(now), 1);
    });

    test('non-leap year Feb 28 to March 1 2025 is due tomorrow on Feb 28', () {
      final now = DateTime(2025, 2, 28, 12, 0);
      final loan = createLoan(
        lentDate: DateTime(2025, 2, 20),
        expectedReturnDate: DateTime(2025, 3, 1),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.daysRemaining(now), 1);
    });

    test('non-leap year expected Feb 28 is overdue on March 1 2025 by 1 day', () {
      final now = DateTime(2025, 3, 1, 9, 0);
      final loan = createLoan(
        lentDate: DateTime(2025, 2, 20),
        expectedReturnDate: DateTime(2025, 2, 28),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 1);
    });

    test('leap year expected Feb 28 is overdue on March 1 2024 by 2 days', () {
      final now = DateTime(2024, 3, 1, 9, 0);
      final loan = createLoan(
        lentDate: DateTime(2024, 2, 20),
        expectedReturnDate: DateTime(2024, 2, 28),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 2);
    });

    test('month transition from April 30 to May 1', () {
      final now = DateTime(2026, 4, 30, 20, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 4, 15),
        expectedReturnDate: DateTime(2026, 5, 1, 8, 0),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.daysRemaining(now), 1);
    });

    test('year transition from Dec 31 to Jan 1', () {
      final now = DateTime(2026, 12, 31, 23, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 12, 20),
        expectedReturnDate: DateTime(2027, 1, 1, 10, 0),
      );
      expect(loan.isDueTomorrow(now), isTrue);
      expect(loan.daysRemaining(now), 1);
    });

    test('year transition expected Dec 31 is overdue on Jan 1 by 1 day', () {
      final now = DateTime(2027, 1, 1, 1, 0);
      final loan = createLoan(
        lentDate: DateTime(2026, 12, 20),
        expectedReturnDate: DateTime(2026, 12, 31, 22, 0),
      );
      expect(loan.isOverdue(now), isTrue);
      expect(loan.daysOverdue(now), 1);
    });

    // 46-60: copyWith and Invariants
    test('copyWith updates itemId and borrowerId', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
      );
      final copy = loan.copyWith(itemId: 99, borrowerId: 88);
      expect(copy.itemId, 99);
      expect(copy.borrowerId, 88);
      expect(copy.id, loan.id);
      expect(copy.itemName, loan.itemName);
    });

    test('copyWith updates notes', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        notes: 'Initial note',
      );
      final copy = loan.copyWith(notes: 'Updated note');
      expect(copy.notes, 'Updated note');
    });

    test('copyWith updates status and returnedDate', () {
      final loan = createLoan(
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
      );
      final returned = DateTime(2026, 11, 9);
      final copy = loan.copyWith(
        status: LoanStatus.returned,
        returnedDate: returned,
      );
      expect(copy.isReturned, isTrue);
      expect(copy.returnedDate, returned);
    });

    test('toMap and fromMap preservation of all fields', () {
      final now = DateTime(2026, 11, 24, 15, 30);
      final loan = Loan(
        id: 42,
        itemId: 10,
        borrowerId: 20,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        returnedDate: DateTime(2026, 11, 14),
        notes: 'Important test note',
        status: LoanStatus.returned,
        createdAt: now,
        itemName: 'Calculus IV',
        itemCategory: ItemCategory.books,
        itemNotes: 'Hardcover',
        borrowerName: 'Hermione Granger',
        borrowerPhone: '+1-555-0100',
      );

      final map = loan.toMap();
      expect(map['id'], 42);
      expect(map['item_id'], 10);
      expect(map['borrower_id'], 20);
      expect(map['status'], 'returned');
      expect(map['notes'], 'Important test note');

      // fromMap joins
      final joinedMap = {
        ...map,
        'item_name': 'Calculus IV',
        'item_category': 'Books',
        'item_notes': 'Hardcover',
        'borrower_name': 'Hermione Granger',
        'borrower_phone': '+1-555-0100',
      };
      final restored = Loan.fromMap(joinedMap);
      expect(restored.id, 42);
      expect(restored.itemId, 10);
      expect(restored.borrowerId, 20);
      expect(restored.status, LoanStatus.returned);
      expect(restored.itemName, 'Calculus IV');
      expect(restored.itemCategory, ItemCategory.books);
      expect(restored.borrowerName, 'Hermione Granger');
      expect(restored.borrowerPhone, '+1-555-0100');
    });

    test('toString contains loan id, item name, and borrower name', () {
      final loan = createLoan(
        id: 777,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        itemName: 'MacBook Charger',
        borrowerName: 'Peter',
      );
      final str = loan.toString();
      expect(str, contains('777'));
      expect(str, contains('MacBook Charger'));
      expect(str, contains('Peter'));
    });

    test('equality and hashCode match for identical fields', () {
      final l1 = createLoan(
        id: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
      );
      final l2 = createLoan(
        id: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
      );
      expect(l1, equals(l2));
      expect(l1.hashCode, equals(l2.hashCode));
    });

    test('equality distinguishes loans with different ids', () {
      final l1 = createLoan(id: 1, lentDate: DateTime(2026, 11, 1), expectedReturnDate: DateTime(2026, 11, 10));
      final l2 = createLoan(id: 2, lentDate: DateTime(2026, 11, 1), expectedReturnDate: DateTime(2026, 11, 10));
      expect(l1, isNot(equals(l2)));
    });

    test('equality distinguishes loans with different status', () {
      final l1 = createLoan(id: 1, lentDate: DateTime(2026, 11, 1), expectedReturnDate: DateTime(2026, 11, 10), status: LoanStatus.out);
      final l2 = createLoan(id: 1, lentDate: DateTime(2026, 11, 1), expectedReturnDate: DateTime(2026, 11, 10), status: LoanStatus.returned);
      expect(l1, isNot(equals(l2)));
    });
  });
}
