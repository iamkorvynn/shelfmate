// [ShelfMate Dev Step 1/2]: Add unit tests for DashboardStats properties
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/dashboard_stats.dart';
import 'package:shelfmate/models/loan.dart';

void main() {
  group('DashboardStats & AppStats', () {
    test('DashboardStats defaults', () {
      const stats = DashboardStats();
      expect(stats.outNow, 0);
      expect(stats.dueSoon, 0);
      expect(stats.overdue, 0);
      expect(stats.totalLentEver, 0);
      expect(stats.nextItemDueBack, isNull);
    });

    test('DashboardStats equality', () {
      const s1 = DashboardStats(outNow: 2, dueSoon: 1, overdue: 0, totalLentEver: 5);
      const s2 = DashboardStats(outNow: 2, dueSoon: 1, overdue: 0, totalLentEver: 5);
      const s3 = DashboardStats(outNow: 3, dueSoon: 1, overdue: 0, totalLentEver: 5);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });

    test('AppStats defaults', () {
      const appStats = AppStats();
      expect(appStats.mostBorrowedItemName, isNull);
      expect(appStats.mostBorrowedItemCount, 0);
      expect(appStats.mostFrequentBorrowerName, isNull);
      expect(appStats.mostFrequentBorrowerCount, 0);
      expect(appStats.longestOutstandingLoan, isNull);
      expect(appStats.longestOutstandingDays, 0);
      expect(appStats.onTimeReturnRate, 0.0);
      expect(appStats.totalReturnedCount, 0);
      expect(appStats.onTimeReturnedCount, 0);
      expect(appStats.loansPerCategory, isEmpty);
      expect(appStats.averageLoanDurationDays, 0.0);
      expect(appStats.totalUniqueBorrowers, 0);
      expect(appStats.totalUniqueItems, 0);
    });

    test('AppStats custom values', () {
      final loan = Loan(
        id: 1,
        itemId: 1,
        borrowerId: 1,
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        createdAt: DateTime(2026, 11, 1),
      );
      final stats = AppStats(
        mostBorrowedItemName: 'Book A',
        mostBorrowedItemCount: 4,
        mostFrequentBorrowerName: 'Alice',
        mostFrequentBorrowerCount: 6,
        longestOutstandingLoan: loan,
        longestOutstandingDays: 23,
        onTimeReturnRate: 85.5,
        totalReturnedCount: 10,
        onTimeReturnedCount: 8,
        loansPerCategory: {ItemCategory.books: 5},
        averageLoanDurationDays: 9.2,
        totalUniqueBorrowers: 3,
        totalUniqueItems: 4,
      );

      expect(stats.mostBorrowedItemName, 'Book A');
      expect(stats.mostBorrowedItemCount, 4);
      expect(stats.mostFrequentBorrowerName, 'Alice');
      expect(stats.longestOutstandingDays, 23);
      expect(stats.onTimeReturnRate, 85.5);
    });
  });
}
