import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';

void main() {
  group('ItemCategory', () {
    test('contains all 5 expected categories', () {
      expect(ItemCategory.values.length, 5);
      expect(ItemCategory.values, contains(ItemCategory.books));
      expect(ItemCategory.values, contains(ItemCategory.notes));
      expect(ItemCategory.values, contains(ItemCategory.chargers));
      expect(ItemCategory.values, contains(ItemCategory.labGear));
      expect(ItemCategory.values, contains(ItemCategory.other));
    });

    test('displayName returns proper string for each category', () {
      expect(ItemCategory.books.displayName, 'Books');
      expect(ItemCategory.notes.displayName, 'Notes');
      expect(ItemCategory.chargers.displayName, 'Chargers');
      expect(ItemCategory.labGear.displayName, 'Lab gear');
      expect(ItemCategory.other.displayName, 'Other');
    });

    test('fromString parses exact display names', () {
      expect(ItemCategory.fromString('Books'), ItemCategory.books);
      expect(ItemCategory.fromString('Notes'), ItemCategory.notes);
      expect(ItemCategory.fromString('Chargers'), ItemCategory.chargers);
      expect(ItemCategory.fromString('Lab gear'), ItemCategory.labGear);
      expect(ItemCategory.fromString('Other'), ItemCategory.other);
    });

    test('fromString parses case-insensitive names', () {
      expect(ItemCategory.fromString('books'), ItemCategory.books);
      expect(ItemCategory.fromString('NOTES'), ItemCategory.notes);
      expect(ItemCategory.fromString('chargers'), ItemCategory.chargers);
      expect(ItemCategory.fromString('lab gear'), ItemCategory.labGear);
      expect(ItemCategory.fromString('other'), ItemCategory.other);
    });

    test('fromString parses enum names', () {
      expect(ItemCategory.fromString('labGear'), ItemCategory.labGear);
      expect(ItemCategory.fromString('LABGEAR'), ItemCategory.labGear);
    });

    test('fromString handles whitespace', () {
      expect(ItemCategory.fromString('  Books  '), ItemCategory.books);
      expect(ItemCategory.fromString('  chargers\n'), ItemCategory.chargers);
    });

    test('fromString returns other for null and unknown values', () {
      expect(ItemCategory.fromString(null), ItemCategory.other);
      expect(ItemCategory.fromString(''), ItemCategory.other);
      expect(ItemCategory.fromString('unknown_category'), ItemCategory.other);
      expect(ItemCategory.fromString('12345'), ItemCategory.other);
    });

    test('icon is non-null for all categories', () {
      for (final cat in ItemCategory.values) {
        expect(cat.icon, isNotNull);
      }
    });

    test('color is non-null for all categories', () {
      for (final cat in ItemCategory.values) {
        expect(cat.color, isNotNull);
      }
    });
  });
}
