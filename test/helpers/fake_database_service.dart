// [ShelfMate Dev Step 3/4]: Implement in-memory borrower operations in FakeDatabaseService
import 'package:shelfmate/database/database_service.dart';
import 'package:shelfmate/models/app_settings.dart';
import 'package:shelfmate/models/borrower.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/dashboard_stats.dart';
import 'package:shelfmate/models/item.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/stats_calculator.dart';

class FakeDatabaseService extends DatabaseService {
  final Map<int, Borrower> borrowersMap = {};
  final Map<int, Item> itemsMap = {};
  final Map<int, Loan> loansMap = {};
  AppSettings settingsData = const AppSettings();

  int _borrowerIdSeq = 1;
  int _itemIdSeq = 1;
  int _loanIdSeq = 1;

  void reset() {
    borrowersMap.clear();
    itemsMap.clear();
    loansMap.clear();
    settingsData = const AppSettings();
    _borrowerIdSeq = 1;
    _itemIdSeq = 1;
    _loanIdSeq = 1;
  }

  // --- Borrowers ---

  @override
  Future<int> insertBorrower(Borrower borrower) async {
    final id = borrower.id ?? _borrowerIdSeq++;
    final b = borrower.copyWith(id: id);
    borrowersMap[id] = b;
    return id;
  }

  @override
  Future<int> updateBorrower(Borrower borrower) async {
    if (borrower.id == null || !borrowersMap.containsKey(borrower.id)) return 0;
    borrowersMap[borrower.id!] = borrower;
    return 1;
  }

  @override
  Future<int> deleteBorrower(int id) async {
    borrowersMap.remove(id);
    loansMap.removeWhere((_, l) => l.borrowerId == id);
    return 1;
  }

  @override
  Future<Borrower?> getBorrower(int id) async {
    final b = borrowersMap[id];
    if (b == null) return null;
    final activeCount = loansMap.values.where((l) => l.borrowerId == id && l.isOut).length;
    final totalCount = loansMap.values.where((l) => l.borrowerId == id).length;
    return b.copyWith(activeLoansCount: activeCount, totalLoansCount: totalCount);
  }

  @override
  Future<List<Borrower>> getAllBorrowers() async {
    final list = borrowersMap.values.map((b) {
      final activeCount = loansMap.values.where((l) => l.borrowerId == b.id && l.isOut).length;
      final totalCount = loansMap.values.where((l) => l.borrowerId == b.id).length;
      return b.copyWith(activeLoansCount: activeCount, totalLoansCount: totalCount);
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  // --- Items ---

  @override
  Future<int> insertItem(Item item) async {
    final id = item.id ?? _itemIdSeq++;
    final it = item.copyWith(id: id);
    itemsMap[id] = it;
    return id;
  }

  @override
  Future<int> updateItem(Item item) async {
    if (item.id == null || !itemsMap.containsKey(item.id)) return 0;
    itemsMap[item.id!] = item;
    return 1;
  }

  @override
  Future<int> deleteItem(int id) async {
    itemsMap.remove(id);
    loansMap.removeWhere((_, l) => l.itemId == id);
    return 1;
  }

  @override
  Future<Item?> getItem(int id) async {
    return itemsMap[id];
  }

  @override
  Future<List<Item>> getAllItems() async {
    final list = itemsMap.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Future<List<Item>> getAvailableItems() async {
    final outItemIds = loansMap.values.where((l) => l.isOut).map((l) => l.itemId).toSet();
    final list = itemsMap.values.where((item) => !outItemIds.contains(item.id)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  // --- Loans ---

  @override
  Future<int> createLoan(Loan loan) async {
    final id = loan.id ?? _loanIdSeq++;
    final l = loan.copyWith(id: id);
    loansMap[id] = l;
    return id;
  }

  @override
  Future<Loan> lendItem({
    int? itemId,
    required String itemName,
    required ItemCategory category,
    String? itemNotes,
    int? borrowerId,
    required String borrowerName,
    String? borrowerPhone,
    required DateTime lentDate,
    required DateTime expectedReturnDate,
    String? loanNotes,
  }) async {
    int effectiveItemId = itemId ?? 0;
    if (effectiveItemId <= 0) {
      effectiveItemId = _itemIdSeq++;
      itemsMap[effectiveItemId] = Item(
        id: effectiveItemId,
        name: itemName.trim(),
        category: category,
        notes: itemNotes,
        createdAt: DateTime.now(),
      );
    }

    int effectiveBorrowerId = borrowerId ?? 0;
    if (effectiveBorrowerId <= 0) {
      final match = borrowersMap.values.cast<Borrower?>().firstWhere(
            (b) => b?.name.toLowerCase() == borrowerName.trim().toLowerCase(),
            orElse: () => null,
          );
      if (match != null) {
        effectiveBorrowerId = match.id!;
      } else {
        effectiveBorrowerId = _borrowerIdSeq++;
        borrowersMap[effectiveBorrowerId] = Borrower(
          id: effectiveBorrowerId,
          name: borrowerName.trim(),
          phone: borrowerPhone,
          createdAt: DateTime.now(),
        );
      }
    }

    final loanId = _loanIdSeq++;
    final now = DateTime.now();
    final loan = Loan(
      id: loanId,
      itemId: effectiveItemId,
      borrowerId: effectiveBorrowerId,
      lentDate: lentDate,
      expectedReturnDate: expectedReturnDate,
      notes: loanNotes,
      status: LoanStatus.out,
      createdAt: now,
      itemName: itemName,
      itemCategory: category,
      itemNotes: itemNotes,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
    );
    loansMap[loanId] = loan;
    return loan;
  }

  @override
  Future<int> markReturned(int loanId, DateTime returnDate) async {
    final loan = loansMap[loanId];
    if (loan == null) return 0;
    loansMap[loanId] = loan.copyWith(
      status: LoanStatus.returned,
      returnedDate: returnDate,
    );
    return 1;
  }

  @override
  Future<int> updateLoan(Loan loan) async {
    if (loan.id == null || !loansMap.containsKey(loan.id)) return 0;
    loansMap[loan.id!] = loan;
    return 1;
  }

  @override
  Future<int> deleteLoan(int id) async {
    loansMap.remove(id);
    return 1;
  }

  @override
  Future<Loan?> getLoan(int id) async {
    return loansMap[id];
  }

  @override
  Future<List<Loan>> getActiveLoans() async {
    final list = loansMap.values.where((l) => l.isOut).toList();
    list.sort((a, b) => a.expectedReturnDate.compareTo(b.expectedReturnDate));
    return list;
  }

  @override
  Future<List<Loan>> getReturnedLoans() async {
    final list = loansMap.values.where((l) => l.isReturned).toList();
    list.sort((a, b) {
      final dateA = a.returnedDate ?? a.createdAt;
      final dateB = b.returnedDate ?? b.createdAt;
      final cmp = dateB.compareTo(dateA);
      return cmp != 0 ? cmp : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return list;
  }

  @override
  Future<List<Loan>> getAllLoans() async {
    final list = loansMap.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Loan>> getLoansByBorrower(int borrowerId) async {
    final list = loansMap.values.where((l) => l.borrowerId == borrowerId).toList();
    list.sort((a, b) => a.expectedReturnDate.compareTo(b.expectedReturnDate));
    return list;
  }

  @override
  Future<List<Loan>> getLoansByItem(int itemId) async {
    final list = loansMap.values.where((l) => l.itemId == itemId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // --- Dashboard & App Stats ---

  @override
  Future<DashboardStats> getDashboardStats({DateTime? referenceDate}) async {
    final active = await getActiveLoans();
    final all = await getAllLoans();
    return StatsCalculator.computeDashboardStats(
      activeLoans: active,
      totalLoansEver: all.length,
      referenceDate: referenceDate,
    );
  }

  @override
  Future<AppStats> getAppStats({DateTime? referenceDate}) async {
    final all = await getAllLoans();
    return StatsCalculator.computeStats(
      allLoans: all,
      totalBorrowers: borrowersMap.length,
      totalItems: itemsMap.length,
      referenceDate: referenceDate,
    );
  }

  // --- Settings ---

  @override
  Future<AppSettings> getSettings() async {
    return settingsData;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    settingsData = settings;
  }

  // --- Export, Backup, Restore, Clear ---

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'borrowers': borrowersMap.values.map((b) => b.toMap()).toList(),
      'items': itemsMap.values.map((i) => i.toMap()).toList(),
      'loans': loansMap.values.map((l) => l.toMap()).toList(),
      'app_settings': settingsData.toMap().entries.map((e) => {'key': e.key, 'value': e.value}).toList(),
    };
  }

  @override
  Future<bool> restoreAllData(Map<String, dynamic> data) async {
    reset();
    if (data['borrowers'] is List) {
      for (final m in data['borrowers'] as List) {
        final b = Borrower.fromMap(m as Map<String, dynamic>);
        borrowersMap[b.id!] = b;
        if (b.id! >= _borrowerIdSeq) _borrowerIdSeq = b.id! + 1;
      }
    }
    if (data['items'] is List) {
      for (final m in data['items'] as List) {
        final i = Item.fromMap(m as Map<String, dynamic>);
        itemsMap[i.id!] = i;
        if (i.id! >= _itemIdSeq) _itemIdSeq = i.id! + 1;
      }
    }
    if (data['loans'] is List) {
      for (final m in data['loans'] as List) {
        final l = Loan.fromMap(m as Map<String, dynamic>);
        loansMap[l.id!] = l;
        if (l.id! >= _loanIdSeq) _loanIdSeq = l.id! + 1;
      }
    }
    if (data['app_settings'] is List) {
      final sMap = <String, String>{};
      for (final item in data['app_settings'] as List) {
        if (item is Map) {
          sMap[item['key'].toString()] = item['value'].toString();
        }
      }
      settingsData = AppSettings.fromMap(sMap);
    }
    return true;
  }

  @override
  Future<void> clearAllData() async {
    reset();
  }
}
