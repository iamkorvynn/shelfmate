import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/services/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final ref = DateTime(2026, 11, 24, 14, 30);

    test('formatDate returns formatted date or empty string for null', () {
      expect(DateFormatter.formatDate(null), '');
      expect(DateFormatter.formatDate(DateTime(2026, 11, 24)), 'Nov 24, 2026');
      expect(DateFormatter.formatDate(DateTime(2026, 1, 5)), 'Jan 5, 2026');
    });

    test('formatDate short format', () {
      expect(DateFormatter.formatDate(DateTime(2026, 11, 24), short: true), 'Nov 24');
      expect(DateFormatter.formatDate(DateTime(2026, 1, 5), short: true), 'Jan 5');
    });

    test('formatIsoDate formats as YYYY-MM-DD', () {
      expect(DateFormatter.formatIsoDate(DateTime(2026, 11, 24)), '2026-11-24');
      expect(DateFormatter.formatIsoDate(DateTime(2026, 5, 9)), '2026-05-09');
    });

    test('formatTime with 12-hour and 24-hour clocks', () {
      const timeMorning = TimeOfDay(hour: 9, minute: 5);
      expect(DateFormatter.formatTime(timeMorning, use24Hour: false), '9:05 AM');
      expect(DateFormatter.formatTime(timeMorning, use24Hour: true), '09:05');

      const timeEvening = TimeOfDay(hour: 17, minute: 45);
      expect(DateFormatter.formatTime(timeEvening, use24Hour: false), '5:45 PM');
      expect(DateFormatter.formatTime(timeEvening, use24Hour: true), '17:45');
    });

    test('formatTimeFromDateTime handles dt properly', () {
      final dt = DateTime(2026, 11, 24, 14, 15);
      expect(DateFormatter.formatTimeFromDateTime(dt, use24Hour: false), '2:15 PM');
      expect(DateFormatter.formatTimeFromDateTime(dt, use24Hour: true), '14:15');
    });

    test('formatRelativeDays handles Today, Tomorrow, Yesterday', () {
      final today = DateTime(2026, 11, 24);
      final tomorrow = DateTime(2026, 11, 25);
      final yesterday = DateTime(2026, 11, 23);

      expect(DateFormatter.formatRelativeDays(today, ref), 'Today');
      expect(DateFormatter.formatRelativeDays(tomorrow, ref), 'Tomorrow');
      expect(DateFormatter.formatRelativeDays(yesterday, ref), 'Yesterday');
    });

    test('formatRelativeDays handles future and overdue days', () {
      final in3Days = DateTime(2026, 11, 27);
      final in10Days = DateTime(2026, 12, 4);
      final overdue2Days = DateTime(2026, 11, 22);
      final overdue5Days = DateTime(2026, 11, 19);

      expect(DateFormatter.formatRelativeDays(in3Days, ref), 'In 3 days');
      expect(DateFormatter.formatRelativeDays(in10Days, ref), 'In 10 days');
      expect(DateFormatter.formatRelativeDays(overdue2Days, ref), '2 days overdue');
      expect(DateFormatter.formatRelativeDays(overdue5Days, ref), '5 days overdue');
    });

    test('formatDuration formats days and weeks', () {
      expect(DateFormatter.formatDuration(0), '0 days');
      expect(DateFormatter.formatDuration(-5), '0 days');
      expect(DateFormatter.formatDuration(1), '1 day');
      expect(DateFormatter.formatDuration(4), '4 days');
      expect(DateFormatter.formatDuration(7), '1 week');
      expect(DateFormatter.formatDuration(14), '2 weeks');
      expect(DateFormatter.formatDuration(10), '10 days (1 w 3d)');
      expect(DateFormatter.formatDuration(17), '17 days (2 w 3d)');
    });
  });
}
