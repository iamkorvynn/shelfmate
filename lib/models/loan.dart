// [ShelfMate Dev Step 3/4]: Add toMap and fromMap serialization with joins to Loan model
import 'category.dart';
import 'loan_status.dart';

class Loan {
  final int? id;
  final int itemId;
  final int borrowerId;
  final DateTime lentDate;
  final DateTime expectedReturnDate;
  final DateTime? returnedDate;
  final String? notes;
  final LoanStatus status;
  final DateTime createdAt;

  // Joined/denormalized fields for display convenience
  final String itemName;
  final ItemCategory itemCategory;
  final String? itemNotes;
  final String borrowerName;
  final String? borrowerPhone;

  const Loan({
    this.id,
    required this.itemId,
    required this.borrowerId,
    required this.lentDate,
    required this.expectedReturnDate,
    this.returnedDate,
    this.notes,
    this.status = LoanStatus.out,
    required this.createdAt,
    this.itemName = '',
    this.itemCategory = ItemCategory.other,
    this.itemNotes,
    this.borrowerName = '',
    this.borrowerPhone,
  });

  bool get isOut => status == LoanStatus.out;
  bool get isReturned => status == LoanStatus.returned;

  /// Compares dates ignoring time of day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  /// True if an active loan is past its expected return date
  bool isOverdue([DateTime? referenceDate]) {
    if (!isOut) return false;
    final now = referenceDate ?? DateTime.now();
    final today = startOfDay(now);
    final expectedDay = startOfDay(expectedReturnDate);
    return today.isAfter(expectedDay);
  }

  /// True if loan is expected to return today
  bool isDueToday([DateTime? referenceDate]) {
    if (!isOut) return false;
    final now = referenceDate ?? DateTime.now();
    return isSameDay(now, expectedReturnDate);
  }

  /// True if loan is expected to return tomorrow
  bool isDueTomorrow([DateTime? referenceDate]) {
    if (!isOut) return false;
    final now = referenceDate ?? DateTime.now();
    final tomorrow = startOfDay(now).add(const Duration(days: 1));
    return isSameDay(tomorrow, expectedReturnDate);
  }

  /// True if loan is due within [days] days from today (including today & tomorrow)
  bool isDueSoon([DateTime? referenceDate, int days = 2]) {
    if (!isOut) return false;
    final now = referenceDate ?? DateTime.now();
    final today = startOfDay(now);
    final expectedDay = startOfDay(expectedReturnDate);
    if (today.isAfter(expectedDay)) return false; // Overdue, not due soon
    final diff = expectedDay.difference(today).inDays;
    return diff >= 0 && diff <= days;
  }

  /// Days remaining until due (negative if overdue)
  int daysRemaining([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = startOfDay(now);
    final expectedDay = startOfDay(expectedReturnDate);
    return expectedDay.difference(today).inDays;
  }

  /// Days overdue (0 if not overdue)
  int daysOverdue([DateTime? referenceDate]) {
    if (!isOverdue(referenceDate)) return 0;
    final now = referenceDate ?? DateTime.now();
    final today = startOfDay(now);
    final expectedDay = startOfDay(expectedReturnDate);
    return today.difference(expectedDay).inDays;
  }

  /// How long the item was/has been out in days (inclusive of at least 1 day)
  int totalDaysOut([DateTime? referenceDate]) {
    final start = startOfDay(lentDate);
    final end = isReturned && returnedDate != null
        ? startOfDay(returnedDate!)
        : startOfDay(referenceDate ?? DateTime.now());
    final diff = end.difference(start).inDays;
    return diff < 1 ? 1 : diff;
  }

  /// Whether a returned item was returned on time
  bool? get wasReturnedOnTime {
    if (!isReturned || returnedDate == null) return null;
    final ret = startOfDay(returnedDate!);
    final exp = startOfDay(expectedReturnDate);
    return !ret.isAfter(exp);
  }

  DueUrgency getUrgency([DateTime? referenceDate]) {
    if (isReturned) return DueUrgency.returned;
    if (isOverdue(referenceDate)) return DueUrgency.overdue;
    if (isDueToday(referenceDate)) return DueUrgency.dueToday;
    if (isDueTomorrow(referenceDate)) return DueUrgency.dueTomorrow;
    if (isDueSoon(referenceDate)) return DueUrgency.dueSoon;
    return DueUrgency.onSchedule;
  }

  Loan copyWith({
    int? id,
    int? itemId,
    int? borrowerId,
    DateTime? lentDate,
    DateTime? expectedReturnDate,
    DateTime? returnedDate,
    String? notes,
    LoanStatus? status,
    DateTime? createdAt,
    String? itemName,
    ItemCategory? itemCategory,
    String? itemNotes,
    String? borrowerName,
    String? borrowerPhone,
  }) {
    return Loan(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      borrowerId: borrowerId ?? this.borrowerId,
      lentDate: lentDate ?? this.lentDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      returnedDate: returnedDate ?? this.returnedDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      itemNotes: itemNotes ?? this.itemNotes,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerPhone: borrowerPhone ?? this.borrowerPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'borrower_id': borrowerId,
      'lent_date': lentDate.toIso8601String(),
      'expected_return_date': expectedReturnDate.toIso8601String(),
      'returned_date': returnedDate?.toIso8601String(),
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      itemId: (map['item_id'] as num?)?.toInt() ?? 0,
      borrowerId: (map['borrower_id'] as num?)?.toInt() ?? 0,
      lentDate: map['lent_date'] != null
          ? DateTime.tryParse(map['lent_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expectedReturnDate: map['expected_return_date'] != null
          ? DateTime.tryParse(map['expected_return_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      returnedDate: map['returned_date'] != null
          ? DateTime.tryParse(map['returned_date'].toString())
          : null,
      notes: map['notes'] as String?,
      status: LoanStatus.fromString(map['status'] as String?),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemName: map['item_name'] as String? ?? '',
      itemCategory: ItemCategory.fromString(map['item_category'] as String?),
      itemNotes: map['item_notes'] as String?,
      borrowerName: map['borrower_name'] as String? ?? '',
      borrowerPhone: map['borrower_phone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Loan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemId == other.itemId &&
          borrowerId == other.borrowerId &&
          lentDate == other.lentDate &&
          expectedReturnDate == other.expectedReturnDate &&
          returnedDate == other.returnedDate &&
          notes == other.notes &&
          status == other.status &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      itemId.hashCode ^
      borrowerId.hashCode ^
      lentDate.hashCode ^
      expectedReturnDate.hashCode ^
      returnedDate.hashCode ^
      notes.hashCode ^
      status.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'Loan(id: $id, item: $itemName, borrower: $borrowerName, status: ${status.name})';
}
