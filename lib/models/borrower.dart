// [ShelfMate Dev Step 1/2]: Define Borrower friend domain model with contact details
class Borrower {
  final int? id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final int activeLoansCount;
  final int totalLoansCount;

  const Borrower({
    this.id,
    required this.name,
    this.phone,
    required this.createdAt,
    this.activeLoansCount = 0,
    this.totalLoansCount = 0,
  });

  Borrower copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
    int? activeLoansCount,
    int? totalLoansCount,
  }) {
    return Borrower(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      activeLoansCount: activeLoansCount ?? this.activeLoansCount,
      totalLoansCount: totalLoansCount ?? this.totalLoansCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      activeLoansCount: (map['active_loans_count'] as num?)?.toInt() ?? 0,
      totalLoansCount: (map['total_loans_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Borrower &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phone.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'Borrower(id: $id, name: $name, phone: $phone)';
}
