// [ShelfMate Dev Step 3/4]: Add unit tests for Loan map serialization and join parsing
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';

void main() {
  group('Loan Model', () {
    final refNow = DateTime(2026, 11, 24, 12, 0);

    test('isOut and isReturned reflect status correctly', () {
      final outLoan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 20),
        expectedReturnDate: DateTime(2026, 11, 27),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(outLoan.isOut, isTrue);
      expect(outLoan.isReturned, isFalse);

      final returnedLoan = outLoan.copyWith(
        status: LoanStatus.returned,
        returnedDate: DateTime(2026, 11, 25),
      );
      expect(returnedLoan.isOut, isFalse);
      expect(returnedLoan.isReturned, isTrue);
    });

    test('isSameDay accurately compares dates ignoring time', () {
      final d1 = DateTime(2026, 11, 24, 8, 30);
      final d2 = DateTime(2026, 11, 24, 23, 59);
      final d3 = DateTime(2026, 11, 25, 0, 1);

      expect(Loan.isSameDay(d1, d2), isTrue);
      expect(Loan.isSameDay(d1, d3), isFalse);
    });

    test('startOfDay and endOfDay helpers', () {
      final dt = DateTime(2026, 11, 24, 15, 30, 45);
      final start = Loan.startOfDay(dt);
      expect(start, DateTime(2026, 11, 24, 0, 0, 0, 0));

      final end = Loan.endOfDay(dt);
      expect(end.year, 2026);
      expect(end.month, 11);
      expect(end.day, 24);
      expect(end.hour, 23);
      expect(end.minute, 59);
    });

    test('isOverdue returns true only when out and past expected date', () {
      final pastLoan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(pastLoan.isOverdue(refNow), isTrue);

      final returnedPastLoan = pastLoan.copyWith(status: LoanStatus.returned);
      expect(returnedPastLoan.isOverdue(refNow), isFalse);

      final todayLoan = pastLoan.copyWith(expectedReturnDate: DateTime(2026, 11, 24, 18, 0));
      expect(todayLoan.isOverdue(refNow), isFalse);

      final futureLoan = pastLoan.copyWith(expectedReturnDate: DateTime(2026, 11, 28));
      expect(futureLoan.isOverdue(refNow), isFalse);
    });

    test('isDueToday returns true when expected return is today', () {
      final todayLoan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 24, 9, 0),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(todayLoan.isDueToday(refNow), isTrue);

      final tomorrowLoan = todayLoan.copyWith(expectedReturnDate: DateTime(2026, 11, 25));
      expect(tomorrowLoan.isDueToday(refNow), isFalse);

      final returnedToday = todayLoan.copyWith(status: LoanStatus.returned);
      expect(returnedToday.isDueToday(refNow), isFalse);
    });

    test('isDueTomorrow returns true when expected return is tomorrow', () {
      final tomorrowLoan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 25, 17, 0),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(tomorrowLoan.isDueTomorrow(refNow), isTrue);

      final dayAfterTomorrow = tomorrowLoan.copyWith(expectedReturnDate: DateTime(2026, 11, 26));
      expect(dayAfterTomorrow.isDueTomorrow(refNow), isFalse);

      final returnedTomorrow = tomorrowLoan.copyWith(status: LoanStatus.returned);
      expect(returnedTomorrow.isDueTomorrow(refNow), isFalse);
    });

    test('isDueSoon handles threshold window', () {
      final loanToday = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 24),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(loanToday.isDueSoon(refNow, 2), isTrue);

      final loanIn2Days = loanToday.copyWith(expectedReturnDate: DateTime(2026, 11, 26));
      expect(loanIn2Days.isDueSoon(refNow, 2), isTrue);

      final loanIn3Days = loanToday.copyWith(expectedReturnDate: DateTime(2026, 11, 27));
      expect(loanIn3Days.isDueSoon(refNow, 2), isFalse);
      expect(loanIn3Days.isDueSoon(refNow, 3), isTrue);

      final overdueLoan = loanToday.copyWith(expectedReturnDate: DateTime(2026, 11, 20));
      expect(overdueLoan.isDueSoon(refNow, 2), isFalse);
    });

    test('daysRemaining calculation', () {
      final loan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 27),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(loan.daysRemaining(refNow), 3);

      final overdueLoan = loan.copyWith(expectedReturnDate: DateTime(2026, 11, 21));
      expect(overdueLoan.daysRemaining(refNow), -3);
    });

    test('daysOverdue calculation', () {
      final loan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 20),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(loan.daysOverdue(refNow), 4);

      final notOverdue = loan.copyWith(expectedReturnDate: DateTime(2026, 11, 26));
      expect(notOverdue.daysOverdue(refNow), 0);
    });

    test('totalDaysOut for active vs returned loans', () {
      final activeLoan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 14),
        expectedReturnDate: DateTime(2026, 11, 28),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      expect(activeLoan.totalDaysOut(refNow), 10);

      final returnedLoan = activeLoan.copyWith(
        status: LoanStatus.returned,
        returnedDate: DateTime(2026, 11, 19),
      );
      expect(returnedLoan.totalDaysOut(refNow), 5);

      final sameDayReturn = activeLoan.copyWith(
        status: LoanStatus.returned,
        returnedDate: DateTime(2026, 11, 14),
      );
      expect(sameDayReturn.totalDaysOut(refNow), 1);
    });

    test('wasReturnedOnTime evaluates correctly', () {
      final loan = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        status: LoanStatus.returned,
        returnedDate: DateTime(2026, 11, 14),
        createdAt: refNow,
      );
      expect(loan.wasReturnedOnTime, isTrue);

      final sameDayReturn = loan.copyWith(returnedDate: DateTime(2026, 11, 15, 20, 0));
      expect(sameDayReturn.wasReturnedOnTime, isTrue);

      final lateReturn = loan.copyWith(returnedDate: DateTime(2026, 11, 16));
      expect(lateReturn.wasReturnedOnTime, isFalse);

      final activeLoan = loan.copyWith(status: LoanStatus.out, returnedDate: null);
      expect(activeLoan.wasReturnedOnTime, isNull);
    });

    test('getUrgency returns appropriate status', () {
      final base = Loan(
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 24),
        status: LoanStatus.out,
        createdAt: refNow,
      );

      expect(base.getUrgency(refNow), DueUrgency.dueToday);
      expect(base.copyWith(expectedReturnDate: DateTime(2026, 11, 20)).getUrgency(refNow), DueUrgency.overdue);
      expect(base.copyWith(expectedReturnDate: DateTime(2026, 11, 25)).getUrgency(refNow), DueUrgency.dueTomorrow);
      expect(base.copyWith(expectedReturnDate: DateTime(2026, 11, 26)).getUrgency(refNow), DueUrgency.dueSoon);
      expect(base.copyWith(expectedReturnDate: DateTime(2026, 12, 1)).getUrgency(refNow), DueUrgency.onSchedule);
      expect(base.copyWith(status: LoanStatus.returned).getUrgency(refNow), DueUrgency.returned);
    });

    test('toMap and fromMap serialization', () {
      final loan = Loan(
        id: 42,
        itemId: 2,
        borrowerId: 3,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        returnedDate: DateTime(2026, 11, 14),
        notes: 'Handle with care',
        status: LoanStatus.returned,
        createdAt: refNow,
        itemName: 'Microscope',
        itemCategory: ItemCategory.labGear,
        borrowerName: 'Sarah',
        borrowerPhone: '555-4321',
      );

      final map = loan.toMap();
      expect(map['id'], 42);
      expect(map['item_id'], 2);
      expect(map['borrower_id'], 3);
      expect(map['status'], 'returned');
      expect(map['notes'], 'Handle with care');

      final fromMapLoan = Loan.fromMap({
        ...map,
        'item_name': 'Microscope',
        'item_category': 'Lab gear',
        'borrower_name': 'Sarah',
        'borrower_phone': '555-4321',
      });
      expect(fromMapLoan.id, 42);
      expect(fromMapLoan.itemName, 'Microscope');
      expect(fromMapLoan.itemCategory, ItemCategory.labGear);
      expect(fromMapLoan.borrowerName, 'Sarah');
      expect(fromMapLoan.borrowerPhone, '555-4321');
      expect(fromMapLoan.status, LoanStatus.returned);
    });

    test('equality and hashCode', () {
      final l1 = Loan(
        id: 1,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      final l2 = Loan(
        id: 1,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        status: LoanStatus.out,
        createdAt: refNow,
      );
      final l3 = l1.copyWith(id: 2);

      expect(l1, equals(l2));
      expect(l1.hashCode, equals(l2.hashCode));
      expect(l1, isNot(equals(l3)));
    });

    test('toString includes item, borrower, and status', () {
      final loan = Loan(
        id: 1,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 10),
        status: LoanStatus.out,
        createdAt: refNow,
        itemName: 'Textbook',
        borrowerName: 'Emma',
      );
      expect(loan.toString(), contains('Textbook'));
      expect(loan.toString(), contains('Emma'));
      expect(loan.toString(), contains('out'));
    });
  });
}
