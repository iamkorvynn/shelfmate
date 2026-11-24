// [ShelfMate Dev Step 1/2]: Add unit tests for Borrower creation and copyWith
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/borrower.dart';

void main() {
  group('Borrower', () {
    final now = DateTime(2026, 11, 24, 10, 0);

    test('creates borrower with required parameters', () {
      final borrower = Borrower(
        name: 'Alice',
        createdAt: now,
      );
      expect(borrower.name, 'Alice');
      expect(borrower.id, isNull);
      expect(borrower.phone, isNull);
      expect(borrower.createdAt, now);
      expect(borrower.activeLoansCount, 0);
      expect(borrower.totalLoansCount, 0);
    });

    test('creates borrower with all parameters', () {
      final borrower = Borrower(
        id: 1,
        name: 'Bob',
        phone: '123-456-7890',
        createdAt: now,
        activeLoansCount: 2,
        totalLoansCount: 5,
      );
      expect(borrower.id, 1);
      expect(borrower.name, 'Bob');
      expect(borrower.phone, '123-456-7890');
      expect(borrower.createdAt, now);
      expect(borrower.activeLoansCount, 2);
      expect(borrower.totalLoansCount, 5);
    });

    test('copyWith updates individual fields', () {
      final borrower = Borrower(
        id: 1,
        name: 'Alice',
        phone: '555',
        createdAt: now,
        activeLoansCount: 1,
        totalLoansCount: 3,
      );

      final updatedName = borrower.copyWith(name: 'Alice Smith');
      expect(updatedName.name, 'Alice Smith');
      expect(updatedName.id, 1);
      expect(updatedName.phone, '555');

      final updatedPhone = borrower.copyWith(phone: '777');
      expect(updatedPhone.phone, '777');

      final updatedCounts = borrower.copyWith(activeLoansCount: 4, totalLoansCount: 8);
      expect(updatedCounts.activeLoansCount, 4);
      expect(updatedCounts.totalLoansCount, 8);

      final updatedId = borrower.copyWith(id: 99);
      expect(updatedId.id, 99);

      final updatedDate = borrower.copyWith(createdAt: DateTime(2026, 12, 1));
      expect(updatedDate.createdAt, DateTime(2026, 12, 1));
    });

    test('toMap converts borrower to map for database insert', () {
      final borrower = Borrower(
        id: 10,
        name: 'Charlie',
        phone: '999-000',
        createdAt: now,
      );
      final map = borrower.toMap();
      expect(map['id'], 10);
      expect(map['name'], 'Charlie');
      expect(map['phone'], '999-000');
      expect(map['created_at'], now.toIso8601String());
    });

    test('toMap omits id when null', () {
      final borrower = Borrower(
        name: 'David',
        createdAt: now,
      );
      final map = borrower.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('toMap handles empty or blank phone as null', () {
      final borrower1 = Borrower(name: 'Eva', phone: '', createdAt: now);
      expect(borrower1.toMap()['phone'], isNull);

      final borrower2 = Borrower(name: 'Eva', phone: '   ', createdAt: now);
      expect(borrower2.toMap()['phone'], isNull);
    });

    test('toMap trims name and phone', () {
      final borrower = Borrower(
        name: '  Frank  ',
        phone: '  12345  ',
        createdAt: now,
      );
      final map = borrower.toMap();
      expect(map['name'], 'Frank');
      expect(map['phone'], '12345');
    });

    test('fromMap parses map correctly', () {
      final map = {
        'id': 5,
        'name': 'Grace',
        'phone': '555-1234',
        'created_at': now.toIso8601String(),
        'active_loans_count': 3,
        'total_loans_count': 7,
      };
      final borrower = Borrower.fromMap(map);
      expect(borrower.id, 5);
      expect(borrower.name, 'Grace');
      expect(borrower.phone, '555-1234');
      expect(borrower.createdAt, now);
      expect(borrower.activeLoansCount, 3);
      expect(borrower.totalLoansCount, 7);
    });

    test('fromMap handles missing or invalid optional fields', () {
      final map = {
        'name': 'Helen',
      };
      final borrower = Borrower.fromMap(map);
      expect(borrower.name, 'Helen');
      expect(borrower.id, isNull);
      expect(borrower.phone, isNull);
      expect(borrower.activeLoansCount, 0);
      expect(borrower.totalLoansCount, 0);
      expect(borrower.createdAt, isNotNull);
    });

    test('equality and hashCode work properly', () {
      final b1 = Borrower(id: 1, name: 'Alice', phone: '123', createdAt: now);
      final b2 = Borrower(id: 1, name: 'Alice', phone: '123', createdAt: now);
      final b3 = Borrower(id: 2, name: 'Alice', phone: '123', createdAt: now);

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('toString contains borrower details', () {
      final borrower = Borrower(id: 1, name: 'Alice', phone: '123', createdAt: now);
      expect(borrower.toString(), contains('Alice'));
      expect(borrower.toString(), contains('123'));
    });
  });
}
