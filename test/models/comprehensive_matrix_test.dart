import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';

void main() {
  group('Comprehensive Date Math Matrix (80 Test Cases)', () {
    final baseDate = DateTime(2026, 6, 1, 12, 0);

    // Test loans with loan durations from 1 to 20 days, evaluated at days -5, 0, 1, mid, due-1, due, due+1, due+5
    final loanDurations = [1, 2, 3, 5, 7, 10, 14, 21, 30, 60];

    for (final duration in loanDurations) {
      final lentDate = baseDate;
      final expectedDate = baseDate.add(Duration(days: duration));

      group('Loan with duration $duration days', () {
        Loan makeLoan({LoanStatus status = LoanStatus.out, DateTime? returnedDate}) {
          return Loan(
            id: duration,
            itemId: duration,
            borrowerId: duration,
            lentDate: lentDate,
            expectedReturnDate: expectedDate,
            returnedDate: returnedDate,
            status: status,
            createdAt: lentDate,
            itemName: 'Item $duration',
            itemCategory: ItemCategory.books,
            borrowerName: 'Borrower $duration',
          );
        }

        test('evaluated at lent date (day 0)', () {
          final loan = makeLoan();
          final evalDate = lentDate;
          if (duration == 0) {
            expect(loan.isDueToday(evalDate), isTrue);
          } else {
            expect(loan.isDueToday(evalDate), isFalse);
            expect(loan.isOverdue(evalDate), isFalse);
          }
          expect(loan.daysRemaining(evalDate), duration);
          expect(loan.daysOverdue(evalDate), 0);
          expect(loan.totalDaysOut(evalDate), 1);
        });

        test('evaluated 1 day before due date', () {
          final loan = makeLoan();
          final evalDate = expectedDate.subtract(const Duration(days: 1));
          expect(loan.isDueTomorrow(evalDate), isTrue);
          expect(loan.isDueToday(evalDate), isFalse);
          expect(loan.isOverdue(evalDate), isFalse);
          expect(loan.isDueSoon(evalDate), isTrue);
          expect(loan.daysRemaining(evalDate), 1);
          expect(loan.daysOverdue(evalDate), 0);
          expect(loan.getUrgency(evalDate), DueUrgency.dueTomorrow);
        });

        test('evaluated on exact due date', () {
          final loan = makeLoan();
          final evalDate = expectedDate;
          expect(loan.isDueToday(evalDate), isTrue);
          expect(loan.isDueTomorrow(evalDate), isFalse);
          expect(loan.isOverdue(evalDate), isFalse);
          expect(loan.daysRemaining(evalDate), 0);
          expect(loan.daysOverdue(evalDate), 0);
          expect(loan.getUrgency(evalDate), DueUrgency.dueToday);
        });

        test('evaluated 1 day after due date', () {
          final loan = makeLoan();
          final evalDate = expectedDate.add(const Duration(days: 1));
          expect(loan.isDueToday(evalDate), isFalse);
          expect(loan.isOverdue(evalDate), isTrue);
          expect(loan.daysRemaining(evalDate), -1);
          expect(loan.daysOverdue(evalDate), 1);
          expect(loan.getUrgency(evalDate), DueUrgency.overdue);
        });

        test('evaluated 5 days after due date', () {
          final loan = makeLoan();
          final evalDate = expectedDate.add(const Duration(days: 5));
          expect(loan.isOverdue(evalDate), isTrue);
          expect(loan.daysRemaining(evalDate), -5);
          expect(loan.daysOverdue(evalDate), 5);
          expect(loan.getUrgency(evalDate), DueUrgency.overdue);
        });

        test('returned on time 1 day before due', () {
          final retDate = expectedDate.subtract(const Duration(days: 1));
          final loan = makeLoan(status: LoanStatus.returned, returnedDate: retDate);
          final evalDate = expectedDate.add(const Duration(days: 10));
          expect(loan.isReturned, isTrue);
          expect(loan.isOverdue(evalDate), isFalse);
          expect(loan.wasReturnedOnTime, isTrue);
          expect(loan.getUrgency(evalDate), DueUrgency.returned);
          expect(loan.totalDaysOut(), duration - 1 < 1 ? 1 : duration - 1);
        });

        test('returned exactly on due date', () {
          final retDate = expectedDate;
          final loan = makeLoan(status: LoanStatus.returned, returnedDate: retDate);
          final evalDate = expectedDate.add(const Duration(days: 10));
          expect(loan.wasReturnedOnTime, isTrue);
          expect(loan.isOverdue(evalDate), isFalse);
          expect(loan.getUrgency(evalDate), DueUrgency.returned);
          expect(loan.totalDaysOut(), duration < 1 ? 1 : duration);
        });

        test('returned late 3 days after due date', () {
          final retDate = expectedDate.add(const Duration(days: 3));
          final loan = makeLoan(status: LoanStatus.returned, returnedDate: retDate);
          final evalDate = expectedDate.add(const Duration(days: 10));
          expect(loan.wasReturnedOnTime, isFalse);
          expect(loan.isOverdue(evalDate), isFalse);
          expect(loan.getUrgency(evalDate), DueUrgency.returned);
          expect(loan.totalDaysOut(), duration + 3);
        });
      });
    }
  });
}
