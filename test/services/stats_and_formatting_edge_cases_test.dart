import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/date_formatter.dart';
import 'package:shelfmate/services/stats_calculator.dart';

void main() {
  group('DateFormatter Detailed Edge Cases', () {
    test('formatDate formats single-digit day and month with leading zeros or standard readable format', () {
      final date = DateTime(2026, 1, 5);
      final formatted = DateFormatter.formatDate(date);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Jan'));
    });

    test('formatDate short for all 12 months', () {
      final months = [
        DateTime(2026, 1, 15),
        DateTime(2026, 2, 15),
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
        DateTime(2026, 5, 15),
        DateTime(2026, 6, 15),
        DateTime(2026, 7, 15),
        DateTime(2026, 8, 15),
        DateTime(2026, 9, 15),
        DateTime(2026, 10, 15),
        DateTime(2026, 11, 15),
        DateTime(2026, 12, 15),
      ];
      final expectedShorts = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (var i = 0; i < 12; i++) {
        expect(DateFormatter.formatDate(months[i], short: true), contains(expectedShorts[i]));
      }
    });

    test('formatTime 12h midnight is 12:00 AM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 0, minute: 0), use24Hour: false), '12:00 AM');
    });

    test('formatTime 12h 00:05 is 12:05 AM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 0, minute: 5), use24Hour: false), '12:05 AM');
    });

    test('formatTime 12h morning 09:30 is 9:30 AM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 9, minute: 30), use24Hour: false), '9:30 AM');
    });

    test('formatTime 12h noon is 12:00 PM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 12, minute: 0), use24Hour: false), '12:00 PM');
    });

    test('formatTime 12h 12:45 is 12:45 PM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 12, minute: 45), use24Hour: false), '12:45 PM');
    });

    test('formatTime 12h afternoon 13:00 is 1:00 PM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 13, minute: 0), use24Hour: false), '1:00 PM');
    });

    test('formatTime 12h evening 23:59 is 11:59 PM', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 23, minute: 59), use24Hour: false), '11:59 PM');
    });

    test('formatTime 24h midnight is 00:00', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 0, minute: 0), use24Hour: true), '00:00');
    });

    test('formatTime 24h single digits padded: 05:07', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 5, minute: 7), use24Hour: true), '05:07');
    });

    test('formatTime 24h afternoon 15:45', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 15, minute: 45), use24Hour: true), '15:45');
    });

    test('formatTime 24h late night 23:59', () {
      expect(DateFormatter.formatTime(const TimeOfDay(hour: 23, minute: 59), use24Hour: true), '23:59');
    });

    test('formatRelativeDays past overdue cases', () {
      final now = DateTime(2026, 11, 24);
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 23), now), 'Yesterday');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 22), now), '2 days overdue');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 20), now), '4 days overdue');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 10, 24), now), '31 days overdue');
      expect(DateFormatter.formatRelativeDays(DateTime(2025, 11, 24), now), '365 days overdue');
    });

    test('formatRelativeDays due today, yesterday and due tomorrow', () {
      final now = DateTime(2026, 11, 24);
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 24), now), 'Today');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 25), now), 'Tomorrow');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 23), now), 'Yesterday');
    });

    test('formatRelativeDays future cases', () {
      final now = DateTime(2026, 11, 24);
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 26), now), 'In 2 days');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 11, 30), now), 'In 6 days');
      expect(DateFormatter.formatRelativeDays(DateTime(2026, 12, 24), now), 'In 30 days');
    });

    test('formatDuration cases', () {
      expect(DateFormatter.formatDuration(0), '0 days');
      expect(DateFormatter.formatDuration(1), '1 day');
      expect(DateFormatter.formatDuration(2), '2 days');
      expect(DateFormatter.formatDuration(7), '1 week');
      expect(DateFormatter.formatDuration(14), '2 weeks');
    });

    test('formatIsoDate and toIsoDate', () {
      final date = DateTime(2026, 11, 24, 10, 30);
      expect(DateFormatter.formatIsoDate(date), '2026-11-24');
    });
  });

  group('StatsCalculator Detailed Edge Cases', () {
    Loan makeLoan({
      int id = 1,
      required String itemName,
      required String borrowerName,
      required ItemCategory category,
      required DateTime lentDate,
      required DateTime expectedDate,
      DateTime? returnedDate,
      LoanStatus status = LoanStatus.out,
    }) {
      return Loan(
        id: id,
        itemId: id,
        borrowerId: id,
        lentDate: lentDate,
        expectedReturnDate: expectedDate,
        returnedDate: returnedDate,
        status: status,
        createdAt: lentDate,
        itemName: itemName,
        itemCategory: category,
        borrowerName: borrowerName,
      );
    }

    test('empty loans gives default zero stats with 100% on time rate', () {
      final stats = StatsCalculator.computeStats(allLoans: [], totalBorrowers: 0, totalItems: 0);
      expect(stats.totalUniqueBorrowers, 0);
      expect(stats.totalUniqueItems, 0);
      expect(stats.onTimeReturnRate, 100.0);
      expect(stats.mostBorrowedItemName, isNull);
      expect(stats.mostFrequentBorrowerName, isNull);
      expect(stats.longestOutstandingLoan, isNull);
      expect(stats.averageLoanDurationDays, 0.0);
      for (final cat in ItemCategory.values) {
        expect(stats.loansPerCategory[cat], 0);
      }
    });

    test('single active loan correctly identified as longest outstanding', () {
      final now = DateTime(2026, 11, 24);
      final loan = makeLoan(
        itemName: 'Book A',
        borrowerName: 'Alice',
        category: ItemCategory.books,
        lentDate: DateTime(2026, 11, 14),
        expectedDate: DateTime(2026, 11, 28),
      );

      final stats = StatsCalculator.computeStats(
        allLoans: [loan],
        totalBorrowers: 1,
        totalItems: 1,
        referenceDate: now,
      );

      expect(stats.longestOutstandingLoan?.itemName, 'Book A');
      expect(stats.longestOutstandingDays, 10);
      expect(stats.mostBorrowedItemName, 'Book A');
      expect(stats.mostBorrowedItemCount, 1);
      expect(stats.mostFrequentBorrowerName, 'Alice');
      expect(stats.mostFrequentBorrowerCount, 1);
    });

    test('all returned loans results in longestOutstandingLoan being null', () {
      final now = DateTime(2026, 11, 24);
      final loan = makeLoan(
        itemName: 'Book A',
        borrowerName: 'Alice',
        category: ItemCategory.books,
        lentDate: DateTime(2026, 11, 1),
        expectedDate: DateTime(2026, 11, 10),
        returnedDate: DateTime(2026, 11, 8),
        status: LoanStatus.returned,
      );

      final stats = StatsCalculator.computeStats(
        allLoans: [loan],
        totalBorrowers: 1,
        totalItems: 1,
        referenceDate: now,
      );

      expect(stats.longestOutstandingLoan, isNull);
      expect(stats.longestOutstandingDays, 0);
      expect(stats.totalReturnedCount, 1);
      expect(stats.onTimeReturnedCount, 1);
      expect(stats.onTimeReturnRate, 100.0);
    });

    test('onTimeReturnRate calculated accurately across varying return ratios', () {
      final base = DateTime(2026, 11, 1);

      // 1 on time, 1 late = 50%
      final l1 = makeLoan(id: 1, itemName: 'A', borrowerName: 'U1', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 5)), returnedDate: base.add(const Duration(days: 4)), status: LoanStatus.returned);
      final l2 = makeLoan(id: 2, itemName: 'B', borrowerName: 'U2', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 5)), returnedDate: base.add(const Duration(days: 7)), status: LoanStatus.returned);

      var stats = StatsCalculator.computeStats(allLoans: [l1, l2], totalBorrowers: 2, totalItems: 2);
      expect(stats.onTimeReturnRate, 50.0);

      // Add 2 more on-time: 3 on time, 1 late = 75%
      final l3 = makeLoan(id: 3, itemName: 'C', borrowerName: 'U3', category: ItemCategory.notes, lentDate: base, expectedDate: base.add(const Duration(days: 5)), returnedDate: base.add(const Duration(days: 5)), status: LoanStatus.returned);
      final l4 = makeLoan(id: 4, itemName: 'D', borrowerName: 'U4', category: ItemCategory.chargers, lentDate: base, expectedDate: base.add(const Duration(days: 5)), returnedDate: base.add(const Duration(days: 2)), status: LoanStatus.returned);

      stats = StatsCalculator.computeStats(allLoans: [l1, l2, l3, l4], totalBorrowers: 4, totalItems: 4);
      expect(stats.onTimeReturnRate, 75.0);
    });

    test('loansPerCategory counts across all categories accurately', () {
      final base = DateTime(2026, 11, 1);
      final loans = [
        makeLoan(id: 1, itemName: 'B1', borrowerName: 'P', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 2, itemName: 'B2', borrowerName: 'P', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 3, itemName: 'B3', borrowerName: 'P', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 4, itemName: 'N1', borrowerName: 'P', category: ItemCategory.notes, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 5, itemName: 'C1', borrowerName: 'P', category: ItemCategory.chargers, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 6, itemName: 'C2', borrowerName: 'P', category: ItemCategory.chargers, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 7, itemName: 'L1', borrowerName: 'P', category: ItemCategory.labGear, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
        makeLoan(id: 8, itemName: 'O1', borrowerName: 'P', category: ItemCategory.other, lentDate: base, expectedDate: base.add(const Duration(days: 2))),
      ];

      final stats = StatsCalculator.computeStats(allLoans: loans, totalBorrowers: 1, totalItems: 8);
      expect(stats.loansPerCategory[ItemCategory.books], 3);
      expect(stats.loansPerCategory[ItemCategory.notes], 1);
      expect(stats.loansPerCategory[ItemCategory.chargers], 2);
      expect(stats.loansPerCategory[ItemCategory.labGear], 1);
      expect(stats.loansPerCategory[ItemCategory.other], 1);
    });

    test('averageLoanDurationDays computes average among returned loans', () {
      final base = DateTime(2026, 11, 1);
      // Duration 4 days
      final l1 = makeLoan(id: 1, itemName: 'A', borrowerName: 'P', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 10)), returnedDate: base.add(const Duration(days: 4)), status: LoanStatus.returned);
      // Duration 6 days
      final l2 = makeLoan(id: 2, itemName: 'B', borrowerName: 'P', category: ItemCategory.books, lentDate: base, expectedDate: base.add(const Duration(days: 10)), returnedDate: base.add(const Duration(days: 6)), status: LoanStatus.returned);

      final stats = StatsCalculator.computeStats(allLoans: [l1, l2], totalBorrowers: 1, totalItems: 2);
      // (4 + 6) / 2 = 5.0
      expect(stats.averageLoanDurationDays, 5.0);
    });

    test('DashboardStats nextItemDueBack picks earliest non-overdue loan', () {
      final now = DateTime(2026, 11, 24);
      final lOverdue = makeLoan(id: 1, itemName: 'Old Item', borrowerName: 'P', category: ItemCategory.books, lentDate: DateTime(2026, 11, 1), expectedDate: DateTime(2026, 11, 20));
      final lNear = makeLoan(id: 2, itemName: 'Due Tomorrow', borrowerName: 'P', category: ItemCategory.books, lentDate: DateTime(2026, 11, 15), expectedDate: DateTime(2026, 11, 25));
      final lFar = makeLoan(id: 3, itemName: 'Due Next Week', borrowerName: 'P', category: ItemCategory.books, lentDate: DateTime(2026, 11, 15), expectedDate: DateTime(2026, 12, 2));

      final stats = StatsCalculator.computeDashboardStats(
        activeLoans: [lOverdue, lNear, lFar],
        totalLoansEver: 3,
        referenceDate: now,
      );

      expect(stats.outNow, 3);
      expect(stats.overdue, 1);
      expect(stats.dueSoon, 1);
      expect(stats.nextItemDueBack?.itemName, 'Due Tomorrow');
    });

    test('DashboardStats nextItemDueBack picks first when all loans are overdue', () {
      final now = DateTime(2026, 11, 24);
      final lVeryOverdue = makeLoan(id: 1, itemName: 'Very Overdue', borrowerName: 'P', category: ItemCategory.books, lentDate: DateTime(2026, 10, 1), expectedDate: DateTime(2026, 10, 10));
      final lSlightlyOverdue = makeLoan(id: 2, itemName: 'Slightly Overdue', borrowerName: 'P', category: ItemCategory.books, lentDate: DateTime(2026, 11, 1), expectedDate: DateTime(2026, 11, 22));

      final stats = StatsCalculator.computeDashboardStats(
        activeLoans: [lVeryOverdue, lSlightlyOverdue],
        totalLoansEver: 2,
        referenceDate: now,
      );

      expect(stats.overdue, 2);
      expect(stats.nextItemDueBack?.itemName, 'Very Overdue');
    });
  });
}
