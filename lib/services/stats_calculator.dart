// [ShelfMate Dev Step 1/5]: Create StatsCalculator service structure
import '../models/category.dart';
import '../models/dashboard_stats.dart';
import '../models/loan.dart';

class StatsCalculator {
  static AppStats computeStats({
    required List<Loan> allLoans,
    required int totalBorrowers,
    required int totalItems,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    if (allLoans.isEmpty) {
      return AppStats(
        totalUniqueBorrowers: totalBorrowers,
        totalUniqueItems: totalItems,
        onTimeReturnRate: 100.0,
        loansPerCategory: {
          for (final c in ItemCategory.values) c: 0,
        },
      );
    }

    final activeLoans = allLoans.where((l) => l.isOut).toList();
    final returnedLoans = allLoans.where((l) => l.isReturned).toList();

    // Most borrowed item
    final itemCounts = <String, int>{};
    for (final l in allLoans) {
      final name = l.itemName.trim();
      if (name.isNotEmpty) {
        itemCounts[name] = (itemCounts[name] ?? 0) + 1;
      }
    }
    String? mostBorrowedItem;
    int mostBorrowedCount = 0;
    itemCounts.forEach((name, count) {
      if (count > mostBorrowedCount) {
        mostBorrowedCount = count;
        mostBorrowedItem = name;
      }
    });

    // Most frequent borrower
    final borrowerCounts = <String, int>{};
    for (final l in allLoans) {
      final name = l.borrowerName.trim();
      if (name.isNotEmpty) {
        borrowerCounts[name] = (borrowerCounts[name] ?? 0) + 1;
      }
    }
    String? mostFrequentBorrower;
    int mostFrequentCount = 0;
    borrowerCounts.forEach((name, count) {
      if (count > mostFrequentCount) {
        mostFrequentCount = count;
        mostFrequentBorrower = name;
      }
    });

    // Longest outstanding loan (active loans)
    Loan? longestOutstanding;
    int longestOutstandingDays = 0;
    for (final l in activeLoans) {
      final days = l.totalDaysOut(now);
      if (days > longestOutstandingDays || longestOutstanding == null) {
        longestOutstandingDays = days;
        longestOutstanding = l;
      }
    }

    // On-time return rate (based on returned loans)
    int onTimeCount = 0;
    for (final l in returnedLoans) {
      if (l.wasReturnedOnTime == true) {
        onTimeCount++;
      }
    }
    final onTimeRate = returnedLoans.isNotEmpty
        ? (onTimeCount / returnedLoans.length) * 100.0
        : 100.0;

    // Loans per category
    final categoryCounts = <ItemCategory, int>{
      for (final cat in ItemCategory.values) cat: 0,
    };
    for (final l in allLoans) {
      categoryCounts[l.itemCategory] = (categoryCounts[l.itemCategory] ?? 0) + 1;
    }

    // Average loan duration in days (for returned items)
    double avgDuration = 0.0;
    if (returnedLoans.isNotEmpty) {
      final totalDays = returnedLoans.fold<int>(
        0,
        (sum, l) => sum + l.totalDaysOut(),
      );
      avgDuration = totalDays / returnedLoans.length;
    }

    return AppStats(
      mostBorrowedItemName: mostBorrowedItem,
      mostBorrowedItemCount: mostBorrowedCount,
      mostFrequentBorrowerName: mostFrequentBorrower,
      mostFrequentBorrowerCount: mostFrequentCount,
      longestOutstandingLoan: longestOutstanding,
      longestOutstandingDays: longestOutstandingDays,
      onTimeReturnRate: onTimeRate,
      totalReturnedCount: returnedLoans.length,
      onTimeReturnedCount: onTimeCount,
      loansPerCategory: categoryCounts,
      averageLoanDurationDays: avgDuration,
      totalUniqueBorrowers: totalBorrowers,
      totalUniqueItems: totalItems,
    );
  }

  static DashboardStats computeDashboardStats({
    required List<Loan> activeLoans,
    required int totalLoansEver,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    int overdueCount = 0;
    int dueSoonCount = 0;
    Loan? nextDue;

    for (final loan in activeLoans) {
      if (loan.isOverdue(now)) {
        overdueCount++;
      } else {
        if (loan.isDueSoon(now)) {
          dueSoonCount++;
        }
        if (nextDue == null || loan.expectedReturnDate.isBefore(nextDue.expectedReturnDate)) {
          nextDue = loan;
        }
      }
    }

    // If all active are overdue, show nearest overdue
    if (nextDue == null && activeLoans.isNotEmpty) {
      nextDue = activeLoans.first;
    }

    return DashboardStats(
      outNow: activeLoans.length,
      dueSoon: dueSoonCount,
      overdue: overdueCount,
      totalLentEver: totalLoansEver,
      nextItemDueBack: nextDue,
    );
  }
}
