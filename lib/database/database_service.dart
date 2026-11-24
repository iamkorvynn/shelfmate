// [ShelfMate Dev Step 4/10]: Implement loan creation and insert query in DatabaseService
import 'package:sqflite/sqflite.dart';
import '../models/app_settings.dart';
import '../models/borrower.dart';
import '../models/category.dart';
import '../models/dashboard_stats.dart';
import '../models/item.dart';
import '../models/loan.dart';
import '../models/loan_status.dart';
import 'database_helper.dart';
import 'tables.dart';

class DatabaseService {
  final DatabaseHelper helper;
  final Database? _overrideDb;

  DatabaseService([DatabaseHelper? helper, Database? overrideDb])
      : helper = helper ?? (overrideDb != null ? DatabaseHelper(overrideDb) : DatabaseHelper()),
        _overrideDb = overrideDb;

  Future<Database> get db async => _overrideDb ?? await helper.database;

  // --- Borrowers ---

  Future<int> insertBorrower(Borrower borrower) async {
    final database = await db;
    return await database.insert(
      Tables.borrowers,
      borrower.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateBorrower(Borrower borrower) async {
    final database = await db;
    return await database.update(
      Tables.borrowers,
      borrower.toMap(),
      where: 'id = ?',
      whereArgs: [borrower.id],
    );
  }

  Future<int> deleteBorrower(int id) async {
    final database = await db;
    return await database.delete(
      Tables.borrowers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Borrower?> getBorrower(int id) async {
    final database = await db;
    final results = await database.rawQuery('''
      SELECT 
        b.id, b.name, b.phone, b.created_at,
        COUNT(CASE WHEN l.status = 'out' THEN 1 END) AS active_loans_count,
        COUNT(l.id) AS total_loans_count
      FROM ${Tables.borrowers} b
      LEFT JOIN ${Tables.loans} l ON b.id = l.borrower_id
      WHERE b.id = ?
      GROUP BY b.id
    ''', [id]);
    if (results.isEmpty) return null;
    return Borrower.fromMap(results.first);
  }

  Future<List<Borrower>> getAllBorrowers() async {
    final database = await db;
    final results = await database.rawQuery('''
      SELECT 
        b.id, b.name, b.phone, b.created_at,
        COUNT(CASE WHEN l.status = 'out' THEN 1 END) AS active_loans_count,
        COUNT(l.id) AS total_loans_count
      FROM ${Tables.borrowers} b
      LEFT JOIN ${Tables.loans} l ON b.id = l.borrower_id
      GROUP BY b.id
      ORDER BY b.name COLLATE NOCASE ASC
    ''');
    return results.map((m) => Borrower.fromMap(m)).toList();
  }

  // --- Items ---

  Future<int> insertItem(Item item) async {
    final database = await db;
    return await database.insert(
      Tables.items,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateItem(Item item) async {
    final database = await db;
    return await database.update(
      Tables.items,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final database = await db;
    return await database.delete(
      Tables.items,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Item?> getItem(int id) async {
    final database = await db;
    final results = await database.query(
      Tables.items,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Item.fromMap(results.first);
  }

  Future<List<Item>> getAllItems() async {
    final database = await db;
    final results = await database.query(
      Tables.items,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return results.map((m) => Item.fromMap(m)).toList();
  }

  Future<List<Item>> getAvailableItems() async {
    final database = await db;
    final results = await database.rawQuery('''
      SELECT i.* 
      FROM ${Tables.items} i
      WHERE i.id NOT IN (
        SELECT item_id FROM ${Tables.loans} WHERE status = 'out'
      )
      ORDER BY i.name COLLATE NOCASE ASC
    ''');
    return results.map((m) => Item.fromMap(m)).toList();
  }

  // --- Loans ---

  static const String _loanSelectSql = '''
    SELECT 
      l.id, l.item_id, l.borrower_id, l.lent_date, l.expected_return_date, 
      l.returned_date, l.notes, l.status, l.created_at,
      i.name AS item_name, i.category AS item_category, i.notes AS item_notes,
      b.name AS borrower_name, b.phone AS borrower_phone
    FROM ${Tables.loans} l
    INNER JOIN ${Tables.items} i ON l.item_id = i.id
    INNER JOIN ${Tables.borrowers} b ON l.borrower_id = b.id
  ''';

  Future<int> createLoan(Loan loan) async {
    final database = await db;
    return await database.insert(
      Tables.loans,
      loan.toMap(),
    );
  }

  /// Convenient method: create an item (or use existing), ensure borrower, and create loan
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
    final database = await db;
    return await database.transaction((txn) async {
      int effectiveItemId = itemId ?? 0;
      if (effectiveItemId <= 0) {
        effectiveItemId = await txn.insert(Tables.items, {
          'name': itemName.trim(),
          'category': category.displayName,
          'notes': itemNotes?.trim().isEmpty ?? true ? null : itemNotes!.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      int effectiveBorrowerId = borrowerId ?? 0;
      if (effectiveBorrowerId <= 0) {
        // Look up by exact name or create
        final existingBorrower = await txn.query(
          Tables.borrowers,
          where: 'name = ? COLLATE NOCASE',
          whereArgs: [borrowerName.trim()],
          limit: 1,
        );
        if (existingBorrower.isNotEmpty) {
          effectiveBorrowerId = existingBorrower.first['id'] as int;
        } else {
          effectiveBorrowerId = await txn.insert(Tables.borrowers, {
            'name': borrowerName.trim(),
            'phone': borrowerPhone?.trim().isEmpty ?? true ? null : borrowerPhone!.trim(),
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      final now = DateTime.now();
      final loanMap = {
        'item_id': effectiveItemId,
        'borrower_id': effectiveBorrowerId,
        'lent_date': lentDate.toIso8601String(),
        'expected_return_date': expectedReturnDate.toIso8601String(),
        'returned_date': null,
        'notes': loanNotes?.trim().isEmpty ?? true ? null : loanNotes!.trim(),
        'status': LoanStatus.out.name,
        'created_at': now.toIso8601String(),
      };

      final loanId = await txn.insert(Tables.loans, loanMap);

      return Loan(
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
    });
  }

  Future<int> markReturned(int loanId, DateTime returnDate) async {
    final database = await db;
    return await database.update(
      Tables.loans,
      {
        'status': LoanStatus.returned.name,
        'returned_date': returnDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  Future<int> updateLoan(Loan loan) async {
    final database = await db;
    return await database.update(
      Tables.loans,
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> deleteLoan(int id) async {
    final database = await db;
    return await database.delete(
      Tables.loans,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Loan?> getLoan(int id) async {
    final database = await db;
    final results = await database.rawQuery(
      '$_loanSelectSql WHERE l.id = ?',
      [id],
    );
    if (results.isEmpty) return null;
    return Loan.fromMap(results.first);
  }

  Future<List<Loan>> getActiveLoans() async {
    final database = await db;
    final results = await database.rawQuery(
      "$_loanSelectSql WHERE l.status = 'out' ORDER BY l.expected_return_date ASC",
    );
    return results.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getReturnedLoans() async {
    final database = await db;
    final results = await database.rawQuery(
      "$_loanSelectSql WHERE l.status = 'returned' ORDER BY l.returned_date DESC, l.id DESC",
    );
    return results.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getAllLoans() async {
    final database = await db;
    final results = await database.rawQuery(
      "$_loanSelectSql ORDER BY l.created_at DESC, l.id DESC",
    );
    return results.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getLoansByBorrower(int borrowerId) async {
    final database = await db;
    final results = await database.rawQuery(
      '$_loanSelectSql WHERE l.borrower_id = ? ORDER BY l.status ASC, l.expected_return_date ASC',
      [borrowerId],
    );
    return results.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getLoansByItem(int itemId) async {
    final database = await db;
    final results = await database.rawQuery(
      '$_loanSelectSql WHERE l.item_id = ? ORDER BY l.created_at DESC',
      [itemId],
    );
    return results.map((m) => Loan.fromMap(m)).toList();
  }

  // --- Dashboard Stats ---

  Future<DashboardStats> getDashboardStats({DateTime? referenceDate}) async {
    final activeLoans = await getActiveLoans();
    final allLoans = await getAllLoans();
    final now = referenceDate ?? DateTime.now();

    int overdueCount = 0;
    int dueSoonCount = 0;
    Loan? nextDue;

    for (final loan in activeLoans) {
      if (loan.isOverdue(now)) {
        overdueCount++;
      } else {
        // not overdue
        if (loan.isDueSoon(now)) {
          dueSoonCount++;
        }
        if (nextDue == null) {
          nextDue = loan;
        } else if (loan.expectedReturnDate.isBefore(nextDue.expectedReturnDate)) {
          nextDue = loan;
        }
      }
    }

    // If all active are overdue, the next due item back is the least overdue or nearest
    if (nextDue == null && activeLoans.isNotEmpty) {
      nextDue = activeLoans.first;
    }

    return DashboardStats(
      outNow: activeLoans.length,
      dueSoon: dueSoonCount,
      overdue: overdueCount,
      totalLentEver: allLoans.length,
      nextItemDueBack: nextDue,
    );
  }

  // --- App Stats ---

  Future<AppStats> getAppStats({DateTime? referenceDate}) async {
    final allLoans = await getAllLoans();
    final activeLoans = await getActiveLoans();
    final returnedLoans = allLoans.where((l) => l.isReturned).toList();
    final borrowers = await getAllBorrowers();
    final items = await getAllItems();
    final now = referenceDate ?? DateTime.now();

    if (allLoans.isEmpty) {
      return AppStats(
        totalUniqueBorrowers: borrowers.length,
        totalUniqueItems: items.length,
      );
    }

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

    // Longest outstanding loan (among currently active loans)
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
      totalUniqueBorrowers: borrowers.length,
      totalUniqueItems: items.length,
    );
  }

  // --- Settings ---

  Future<AppSettings> getSettings() async {
    final database = await db;
    final rows = await database.query(Tables.appSettings);
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String;
    }
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final database = await db;
    final batch = database.batch();
    settings.toMap().forEach((key, value) {
      batch.insert(
        Tables.appSettings,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  // --- Export, Backup, Restore, Clear ---

  Future<Map<String, dynamic>> exportAllData() async {
    final database = await db;
    final borrowers = await database.query(Tables.borrowers);
    final items = await database.query(Tables.items);
    final loans = await database.query(Tables.loans);
    final settings = await database.query(Tables.appSettings);

    return {
      'version': DatabaseHelper.dbVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'borrowers': borrowers,
      'items': items,
      'loans': loans,
      'app_settings': settings,
    };
  }

  Future<bool> restoreAllData(Map<String, dynamic> data) async {
    final database = await db;
    return await database.transaction((txn) async {
      await txn.delete(Tables.loans);
      await txn.delete(Tables.items);
      await txn.delete(Tables.borrowers);
      await txn.delete(Tables.appSettings);

      final borrowers = (data['borrowers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final b in borrowers) {
        await txn.insert(Tables.borrowers, b);
      }

      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final i in items) {
        await txn.insert(Tables.items, i);
      }

      final loans = (data['loans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final l in loans) {
        await txn.insert(Tables.loans, l);
      }

      final settings = (data['app_settings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final s in settings) {
        await txn.insert(Tables.appSettings, s);
      }

      return true;
    });
  }

  Future<void> clearAllData() async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete(Tables.loans);
      await txn.delete(Tables.items);
      await txn.delete(Tables.borrowers);
      await txn.delete(Tables.appSettings);
    });
  }
}
