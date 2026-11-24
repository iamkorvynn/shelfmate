import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default settings values', () {
      const settings = AppSettings();
      expect(settings.defaultLoanPeriodDays, 14);
      expect(settings.reminderHour, 9);
      expect(settings.reminderMinute, 0);
      expect(settings.use24HourClock, isFalse);
      expect(settings.reminderTime, const TimeOfDay(hour: 9, minute: 0));
    });

    test('custom settings values', () {
      const settings = AppSettings(
        defaultLoanPeriodDays: 21,
        reminderHour: 18,
        reminderMinute: 30,
        use24HourClock: true,
      );
      expect(settings.defaultLoanPeriodDays, 21);
      expect(settings.reminderHour, 18);
      expect(settings.reminderMinute, 30);
      expect(settings.use24HourClock, isTrue);
      expect(settings.reminderTime, const TimeOfDay(hour: 18, minute: 30));
    });

    test('copyWith updates individual fields', () {
      const settings = AppSettings();
      final updatedDays = settings.copyWith(defaultLoanPeriodDays: 7);
      expect(updatedDays.defaultLoanPeriodDays, 7);
      expect(updatedDays.reminderHour, 9);

      final updatedHour = settings.copyWith(reminderHour: 10);
      expect(updatedHour.reminderHour, 10);

      final updatedMinute = settings.copyWith(reminderMinute: 45);
      expect(updatedMinute.reminderMinute, 45);

      final updatedClock = settings.copyWith(use24HourClock: true);
      expect(updatedClock.use24HourClock, isTrue);
    });

    test('toMap and fromMap conversion', () {
      const settings = AppSettings(
        defaultLoanPeriodDays: 30,
        reminderHour: 8,
        reminderMinute: 15,
        use24HourClock: true,
      );
      final map = settings.toMap();
      expect(map['default_loan_period_days'], '30');
      expect(map['reminder_hour'], '8');
      expect(map['reminder_minute'], '15');
      expect(map['use_24_hour_clock'], '1');

      final fromMap = AppSettings.fromMap(map);
      expect(fromMap, equals(settings));
    });

    test('fromMap with missing/invalid values falls back to defaults', () {
      final fromMap = AppSettings.fromMap({});
      expect(fromMap.defaultLoanPeriodDays, 14);
      expect(fromMap.reminderHour, 9);
      expect(fromMap.reminderMinute, 0);
      expect(fromMap.use24HourClock, isFalse);
    });

    test('equality and hashCode', () {
      const s1 = AppSettings(defaultLoanPeriodDays: 14);
      const s2 = AppSettings(defaultLoanPeriodDays: 14);
      const s3 = AppSettings(defaultLoanPeriodDays: 28);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}
