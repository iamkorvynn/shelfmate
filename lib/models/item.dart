// [ShelfMate Dev Step 1/2]: Define Item domain model with category and timestamps
import 'category.dart';

class Item {
  final int? id;
  final String name;
  final ItemCategory category;
  final String? notes;
  final DateTime createdAt;

  const Item({
    this.id,
    required this.name,
    required this.category,
    this.notes,
    required this.createdAt,
  });

  Item copyWith({
    int? id,
    String? name,
    ItemCategory? category,
    String? notes,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'category': category.displayName,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: ItemCategory.fromString(map['category'] as String?),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      category.hashCode ^
      notes.hashCode ^
      createdAt.hashCode;

  @override
  String toString() => 'Item(id: $id, name: $name, category: ${category.displayName})';
}
