import 'package:material_ui/material_ui.dart';

class AppSettings {
  final int defaultLoanPeriodDays;
  final int reminderHour;
  final int reminderMinute;
  final bool use24HourClock;

  const AppSettings({
    this.defaultLoanPeriodDays = 14,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.use24HourClock = false,
  });

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  AppSettings copyWith({
    int? defaultLoanPeriodDays,
    int? reminderHour,
    int? reminderMinute,
    bool? use24HourClock,
  }) {
    return AppSettings(
      defaultLoanPeriodDays:
          defaultLoanPeriodDays ?? this.defaultLoanPeriodDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      use24HourClock: use24HourClock ?? this.use24HourClock,
    );
  }

  Map<String, String> toMap() {
    return {
      'default_loan_period_days': defaultLoanPeriodDays.toString(),
      'reminder_hour': reminderHour.toString(),
      'reminder_minute': reminderMinute.toString(),
      'use_24_hour_clock': use24HourClock ? '1' : '0',
    };
  }

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      defaultLoanPeriodDays:
          int.tryParse(map['default_loan_period_days'] ?? '') ?? 14,
      reminderHour: int.tryParse(map['reminder_hour'] ?? '') ?? 9,
      reminderMinute: int.tryParse(map['reminder_minute'] ?? '') ?? 0,
      use24HourClock: map['use_24_hour_clock'] == '1',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          defaultLoanPeriodDays == other.defaultLoanPeriodDays &&
          reminderHour == other.reminderHour &&
          reminderMinute == other.reminderMinute &&
          use24HourClock == other.use24HourClock;

  @override
  int get hashCode =>
      defaultLoanPeriodDays.hashCode ^
      reminderHour.hashCode ^
      reminderMinute.hashCode ^
      use24HourClock.hashCode;
}
