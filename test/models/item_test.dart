import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/item.dart';

void main() {
  group('Item', () {
    final now = DateTime(2026, 11, 24, 10, 0);

    test('creates item with required fields', () {
      final item = Item(
        name: 'Calculus 101',
        category: ItemCategory.books,
        createdAt: now,
      );
      expect(item.id, isNull);
      expect(item.name, 'Calculus 101');
      expect(item.category, ItemCategory.books);
      expect(item.notes, isNull);
      expect(item.createdAt, now);
    });

    test('creates item with all fields', () {
      final item = Item(
        id: 10,
        name: '65W Anker Charger',
        category: ItemCategory.chargers,
        notes: 'White color with brainded cable',
        createdAt: now,
      );
      expect(item.id, 10);
      expect(item.name, '65W Anker Charger');
      expect(item.category, ItemCategory.chargers);
      expect(item.notes, 'White color with brainded cable');
      expect(item.createdAt, now);
    });

    test('copyWith works for all fields', () {
      final item = Item(
        id: 1,
        name: 'Old Name',
        category: ItemCategory.other,
        notes: 'Note 1',
        createdAt: now,
      );

      final updatedName = item.copyWith(name: 'New Name');
      expect(updatedName.name, 'New Name');
      expect(updatedName.category, ItemCategory.other);

      final updatedCat = item.copyWith(category: ItemCategory.labGear);
      expect(updatedCat.category, ItemCategory.labGear);

      final updatedNotes = item.copyWith(notes: 'New Note');
      expect(updatedNotes.notes, 'New Note');

      final updatedId = item.copyWith(id: 99);
      expect(updatedId.id, 99);

      final updatedDate = item.copyWith(createdAt: DateTime(2026, 1, 1));
      expect(updatedDate.createdAt, DateTime(2026, 1, 1));
    });

    test('toMap converts to map with trimmed values', () {
      final item = Item(
        id: 2,
        name: '  Oscilloscope  ',
        category: ItemCategory.labGear,
        notes: '  Lab room 402  ',
        createdAt: now,
      );
      final map = item.toMap();
      expect(map['id'], 2);
      expect(map['name'], 'Oscilloscope');
      expect(map['category'], 'Lab gear');
      expect(map['notes'], 'Lab room 402');
      expect(map['created_at'], now.toIso8601String());
    });

    test('toMap handles empty notes as null and omits id when null', () {
      final item = Item(
        name: 'Notebook',
        category: ItemCategory.notes,
        notes: '   ',
        createdAt: now,
      );
      final map = item.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['notes'], isNull);
    });

    test('fromMap parses map correctly', () {
      final map = {
        'id': 7,
        'name': 'Organic Chem Notes',
        'category': 'Notes',
        'notes': 'Unit 1 to 4',
        'created_at': now.toIso8601String(),
      };
      final item = Item.fromMap(map);
      expect(item.id, 7);
      expect(item.name, 'Organic Chem Notes');
      expect(item.category, ItemCategory.notes);
      expect(item.notes, 'Unit 1 to 4');
      expect(item.createdAt, now);
    });

    test('fromMap handles unknown category and null dates', () {
      final map = {
        'name': 'Mystery Item',
        'category': 'UnknownStuff',
      };
      final item = Item.fromMap(map);
      expect(item.category, ItemCategory.other);
      expect(item.createdAt, isNotNull);
    });

    test('equality and hashCode', () {
      final i1 = Item(id: 1, name: 'Item', category: ItemCategory.books, createdAt: now);
      final i2 = Item(id: 1, name: 'Item', category: ItemCategory.books, createdAt: now);
      final i3 = Item(id: 2, name: 'Item', category: ItemCategory.books, createdAt: now);

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
    });

    test('toString includes item name and category', () {
      final item = Item(id: 1, name: 'Physics Book', category: ItemCategory.books, createdAt: now);
      expect(item.toString(), contains('Physics Book'));
      expect(item.toString(), contains('Books'));
    });
  });
}
