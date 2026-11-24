import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/models/loan_status.dart';
import 'package:shelfmate/services/export_service.dart';

void main() {
  group('ExportService', () {
    final ref = DateTime(2026, 11, 24, 12, 0);

    test('exports empty loan list with header only', () {
      final csv = ExportService.exportLoansToCsv([], ref);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1);
      expect(lines.first, contains('ID,Item Name,Category,Borrower,Phone'));
    });

    test('exports loans with correct columns and dates', () {
      final loan = Loan(
        id: 1,
        itemId: 10,
        borrowerId: 20,
        itemName: 'Flutter in Action',
        itemCategory: ItemCategory.books,
        borrowerName: 'Alice',
        borrowerPhone: '555-1234',
        lentDate: DateTime(2026, 11, 10),
        expectedReturnDate: DateTime(2026, 11, 24),
        returnedDate: DateTime(2026, 11, 23),
        notes: 'Great condition',
        status: LoanStatus.returned,
        createdAt: ref,
      );

      final csv = ExportService.exportLoansToCsv([loan], ref);
      final lines = csv.trim().split('\n');
      expect(lines.length, 2);
      final dataRow = lines[1];
      expect(dataRow, contains('Flutter in Action'));
      expect(dataRow, contains('Books'));
      expect(dataRow, contains('Alice'));
      expect(dataRow, contains('555-1234'));
      expect(dataRow, contains('2026-11-10'));
      expect(dataRow, contains('2026-11-24'));
      expect(dataRow, contains('2026-11-23'));
      expect(dataRow, contains('Returned'));
      expect(dataRow, contains('Great condition'));
    });

    test('escapes commas, quotes, and newlines in CSV fields', () {
      final loan = Loan(
        id: 2,
        itemId: 11,
        borrowerId: 21,
        itemName: 'Book, "Volume 1"',
        itemCategory: ItemCategory.other,
        borrowerName: 'Bob, Jr.',
        lentDate: DateTime(2026, 11, 1),
        expectedReturnDate: DateTime(2026, 11, 15),
        notes: 'Line 1\nLine 2',
        status: LoanStatus.out,
        createdAt: ref,
      );

      final csv = ExportService.exportLoansToCsv([loan], ref);
      expect(csv, contains('"Book, ""Volume 1"""'));
      expect(csv, contains('"Bob, Jr."'));
      expect(csv, contains('"Line 1\nLine 2"'));
    });

    test('handles multiple loans export', () {
      final loans = List.generate(
        5,
        (i) => Loan(
          id: i + 1,
          itemId: i + 1,
          borrowerId: i + 1,
          itemName: 'Item $i',
          itemCategory: ItemCategory.values[i % 5],
          borrowerName: 'Friend $i',
          lentDate: DateTime(2026, 11, 1),
          expectedReturnDate: DateTime(2026, 11, 15),
          status: i.isEven ? LoanStatus.out : LoanStatus.returned,
          createdAt: ref,
        ),
      );

      final csv = ExportService.exportLoansToCsv(loans, ref);
      final lines = csv.trim().split('\n');
      expect(lines.length, 6); // header + 5 items
    });
  });
}
