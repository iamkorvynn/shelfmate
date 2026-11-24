// [ShelfMate Dev Step 1/4]: Add unit tests for most-borrowed item calculations
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/stats_calculator.dart';

void main() {
  group('StatsCalculator', () {
    final ref = DateTime(2026, 11, 24, 12, 0);

    test('computeStats returns zeros when loans are empty', () {
      final stats = StatsCalculator.computeStats(
        allLoans: [],
        totalBorrowers: 2,
        totalItems: 3,
        referenceDate: ref,
      );

      expect(stats.mostBorrowedItemName, isNull);
      expect(stats.mostBorrowedItemCount, 0);
      expect(stats.mostFrequentBorrowerName, isNull);
      expect(stats.mostFrequentBorrowerCount, 0);
      expect(stats.longestOutstandingLoan, isNull);
      expect(stats.longestOutstandingDays, 0);
      expect(stats.onTimeReturnRate, 100.0);
      expect(stats.totalReturnedCount, 0);
      expect(stats.onTimeReturnedCount, 0);
      expect(stats.averageLoanDurationDays, 0.0);
      expect(stats.totalUniqueBorrowers, 2);
      expect(stats.totalUniqueItems, 3);
      for (final cat in ItemCategory.values) {
        expect(stats.loansPerCategory[cat], 0);
      }
    });

    test('calculates most borrowed item correctly', () {
      final loans = [
        Loan(
          itemId: 1,
          borrowerId: 1,
          itemName: 'Physics Textbook',
          itemCategory: ItemCategory.books,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
        Loan(
          itemId: 1,
          borrowerId: 2,
          itemName: 'Physics Textbook',
          itemCategory: ItemCategory.books,
          lentDate: DateTime(2026, 11, 11),
          expectedReturnDate: DateTime(2026, 11, 18),
          createdAt: ref,
        ),
        Loan(
          itemId: 2,
          borrowerId: 3,
          itemName: 'Charger',
          itemCategory: ItemCategory.chargers,
          lentDate: DateTime(2026, 11, 5),
          expectedReturnDate: DateTime(2026, 11, 12),
          createdAt: ref,
        ),
      ];

      final stats = StatsCalculator.computeStats(
        allLoans: loans,
        totalBorrowers: 3,
        totalItems: 2,
        referenceDate: ref,
      );

      expect(stats.mostBorrowedItemName, 'Physics Textbook');
      expect(stats.mostBorrowedItemCount, 2);
    });

    test('calculates most frequent borrower correctly', () {
      final loans = [
        Loan(
          itemId: 1,
          borrowerId: 1,
          borrowerName: 'Sarah',
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
        Loan(
          itemId: 2,
          borrowerId: 1,
          borrowerName: 'Sarah',
          lentDate: DateTime(2026, 11, 2),
          expectedReturnDate: DateTime(2026, 11, 12),
          createdAt: ref,
        ),
        Loan(
          itemId: 3,
          borrowerId: 2,
          borrowerName: 'John',
          lentDate: DateTime(2026, 11, 5),
          expectedReturnDate: DateTime(2026, 11, 15),
          createdAt: ref,
        ),
      ];

      final stats = StatsCalculator.computeStats(
        allLoans: loans,
        totalBorrowers: 2,
        totalItems: 3,
        referenceDate: ref,
      );

      expect(stats.mostFrequentBorrowerName, 'Sarah');
      expect(stats.mostFrequentBorrowerCount, 2);
    });

    test('calculates longest outstanding loan among active loans', () {
      final loans = [
        // Out for 14 days (lent Nov 10 to Nov 24)
        Loan(
          itemId: 1,
          borrowerId: 1,
          itemName: 'Old Loan',
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 10),
          expectedReturnDate: DateTime(2026, 11, 28),
          createdAt: ref,
        ),
        // Out for 4 days (lent Nov 20 to Nov 24)
        Loan(
          itemId: 2,
          borrowerId: 2,
          itemName: 'Recent Loan',
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 20),
          expectedReturnDate: DateTime(2026, 11, 28),
          createdAt: ref,
        ),
        // Returned loan (was out for 30 days, but is returned, so excluded from active longest)
        Loan(
          itemId: 3,
          borrowerId: 3,
          itemName: 'Returned Loan',
          status: LoanStatus.returned,
          lentDate: DateTime(2026, 10, 1),
          expectedReturnDate: DateTime(2026, 10, 31),
          returnedDate: DateTime(2026, 10, 31),
          createdAt: ref,
        ),
      ];

      final stats = StatsCalculator.computeStats(
        allLoans: loans,
        totalBorrowers: 3,
        totalItems: 3,
        referenceDate: ref,
      );

      expect(stats.longestOutstandingLoan?.itemName, 'Old Loan');
      expect(stats.longestOutstandingDays, 14);
    });

    test('calculates on-time return rate accurately', () {
      final loans = [
        // Returned on time
        Loan(
          itemId: 1,
          borrowerId: 1,
          status: LoanStatus.returned,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          returnedDate: DateTime(2026, 11, 9),
          createdAt: ref,
        ),
        // Returned exactly on due date (on time)
        Loan(
          itemId: 2,
          borrowerId: 2,
          status: LoanStatus.returned,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          returnedDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
        // Returned late
        Loan(
          itemId: 3,
          borrowerId: 3,
          status: LoanStatus.returned,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          returnedDate: DateTime(2026, 11, 12),
          createdAt: ref,
        ),
        // Active loan (does not affect return rate)
        Loan(
          itemId: 4,
          borrowerId: 4,
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
      ];

      final stats = StatsCalculator.computeStats(
        allLoans: loans,
        totalBorrowers: 4,
        totalItems: 4,
        referenceDate: ref,
      );

      expect(stats.totalReturnedCount, 3);
      expect(stats.onTimeReturnedCount, 2);
      expect(stats.onTimeReturnRate, closeTo(66.66, 0.1));
    });

    test('calculates loans per category breakdown', () {
      final loans = [
        Loan(
          itemId: 1,
          borrowerId: 1,
          itemCategory: ItemCategory.books,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
        Loan(
          itemId: 2,
          borrowerId: 2,
          itemCategory: ItemCategory.books,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
        Loan(
          itemId: 3,
          borrowerId: 3,
          itemCategory: ItemCategory.chargers,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 10),
          createdAt: ref,
        ),
      ];

      final stats = StatsCalculator.computeStats(
        allLoans: loans,
        totalBorrowers: 3,
        totalItems: 3,
        referenceDate: ref,
      );

      expect(stats.loansPerCategory[ItemCategory.books], 2);
      expect(stats.loansPerCategory[ItemCategory.chargers], 1);
      expect(stats.loansPerCategory[ItemCategory.notes], 0);
      expect(stats.loansPerCategory[ItemCategory.labGear], 0);
      expect(stats.loansPerCategory[ItemCategory.other], 0);
    });

    test('computeDashboardStats handles empty and mixed loans', () {
      final empty = StatsCalculator.computeDashboardStats(
        activeLoans: [],
        totalLoansEver: 0,
        referenceDate: ref,
      );
      expect(empty.outNow, 0);
      expect(empty.dueSoon, 0);
      expect(empty.overdue, 0);
      expect(empty.totalLentEver, 0);
      expect(empty.nextItemDueBack, isNull);

      final active = [
        // Overdue by 4 days
        Loan(
          id: 1,
          itemId: 1,
          borrowerId: 1,
          itemName: 'Overdue Item',
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 20),
          createdAt: ref,
        ),
        // Due today (Nov 24)
        Loan(
          id: 2,
          itemId: 2,
          borrowerId: 2,
          itemName: 'Due Today Item',
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 10),
          expectedReturnDate: DateTime(2026, 11, 24),
          createdAt: ref,
        ),
        // Due in 3 days (Nov 27)
        Loan(
          id: 3,
          itemId: 3,
          borrowerId: 3,
          itemName: 'Later Item',
          status: LoanStatus.out,
          lentDate: DateTime(2026, 11, 15),
          expectedReturnDate: DateTime(2026, 11, 27),
          createdAt: ref,
        ),
      ];

      final dash = StatsCalculator.computeDashboardStats(
        activeLoans: active,
        totalLoansEver: 5,
        referenceDate: ref,
      );

      expect(dash.outNow, 3);
      expect(dash.overdue, 1);
      expect(dash.dueSoon, 1); // Due today counts as due soon
      expect(dash.totalLentEver, 5);
      expect(dash.nextItemDueBack?.itemName, 'Due Today Item');
    });
  });
}
