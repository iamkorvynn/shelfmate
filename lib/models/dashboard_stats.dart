import 'category.dart';
import 'loan.dart';

class DashboardStats {
  final int outNow;
  final int dueSoon;
  final int overdue;
  final int totalLentEver;
  final Loan? nextItemDueBack;

  const DashboardStats({
    this.outNow = 0,
    this.dueSoon = 0,
    this.overdue = 0,
    this.totalLentEver = 0,
    this.nextItemDueBack,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          outNow == other.outNow &&
          dueSoon == other.dueSoon &&
          overdue == other.overdue &&
          totalLentEver == other.totalLentEver &&
          nextItemDueBack?.id == other.nextItemDueBack?.id;

  @override
  int get hashCode =>
      outNow.hashCode ^
      dueSoon.hashCode ^
      overdue.hashCode ^
      totalLentEver.hashCode ^
      nextItemDueBack.hashCode;
}

class AppStats {
  final String? mostBorrowedItemName;
  final int mostBorrowedItemCount;
  final String? mostFrequentBorrowerName;
  final int mostFrequentBorrowerCount;
  final Loan? longestOutstandingLoan;
  final int longestOutstandingDays;
  final double onTimeReturnRate; // 0.0 to 100.0
  final int totalReturnedCount;
  final int onTimeReturnedCount;
  final Map<ItemCategory, int> loansPerCategory;
  final double averageLoanDurationDays;
  final int totalUniqueBorrowers;
  final int totalUniqueItems;

  const AppStats({
    this.mostBorrowedItemName,
    this.mostBorrowedItemCount = 0,
    this.mostFrequentBorrowerName,
    this.mostFrequentBorrowerCount = 0,
    this.longestOutstandingLoan,
    this.longestOutstandingDays = 0,
    this.onTimeReturnRate = 0.0,
    this.totalReturnedCount = 0,
    this.onTimeReturnedCount = 0,
    this.loansPerCategory = const {},
    this.averageLoanDurationDays = 0.0,
    this.totalUniqueBorrowers = 0,
    this.totalUniqueItems = 0,
  });
}
