// [ShelfMate Dev Step 1/2]: Add unit tests for LoanStatus parsing and display names
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/models/loan_status.dart';

void main() {
  group('LoanStatus', () {
    test('contains out and returned', () {
      expect(LoanStatus.values.length, 2);
      expect(LoanStatus.values, contains(LoanStatus.out));
      expect(LoanStatus.values, contains(LoanStatus.returned));
    });

    test('displayName returns Out and Returned', () {
      expect(LoanStatus.out.displayName, 'Out');
      expect(LoanStatus.returned.displayName, 'Returned');
    });

    test('fromString parses exact and case-insensitive names', () {
      expect(LoanStatus.fromString('out'), LoanStatus.out);
      expect(LoanStatus.fromString('OUT'), LoanStatus.out);
      expect(LoanStatus.fromString('Out'), LoanStatus.out);
      expect(LoanStatus.fromString('returned'), LoanStatus.returned);
      expect(LoanStatus.fromString('RETURNED'), LoanStatus.returned);
      expect(LoanStatus.fromString('Returned'), LoanStatus.returned);
    });

    test('fromString falls back to out on null and unknown values', () {
      expect(LoanStatus.fromString(null), LoanStatus.out);
      expect(LoanStatus.fromString(''), LoanStatus.out);
      expect(LoanStatus.fromString('unknown_status'), LoanStatus.out);
    });
  });

  group('DueUrgency', () {
    test('all urgency values have non-null properties', () {
      for (final urgency in DueUrgency.values) {
        expect(urgency.label, isNotEmpty);
        expect(urgency.textColor, isNotNull);
        expect(urgency.backgroundColor, isNotNull);
        expect(urgency.icon, isNotNull);
      }
    });

    test('labels match expected names', () {
      expect(DueUrgency.overdue.label, 'Overdue');
      expect(DueUrgency.dueToday.label, 'Due Today');
      expect(DueUrgency.dueTomorrow.label, 'Due Tomorrow');
      expect(DueUrgency.dueSoon.label, 'Due Soon');
      expect(DueUrgency.onSchedule.label, 'On Schedule');
      expect(DueUrgency.returned.label, 'Returned');
    });
  });
}
