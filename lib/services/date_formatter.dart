// [ShelfMate Dev Step 1/3]: Create DateFormatter utility with standard date formats
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class DateFormatter {
  static final DateFormat _defaultDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _time12Format = DateFormat('h:mm a');
  static final DateFormat _time24Format = DateFormat('HH:mm');

  static String formatDate(DateTime? date, {bool short = false}) {
    if (date == null) return '';
    return short ? _shortDateFormat.format(date) : _defaultDateFormat.format(date);
  }

  static String formatIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  static String formatTime(TimeOfDay time, {bool use24Hour = false}) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return use24Hour ? _time24Format.format(dt) : _time12Format.format(dt);
  }

  static String formatTimeFromDateTime(DateTime dt, {bool use24Hour = false}) {
    return use24Hour ? _time24Format.format(dt) : _time12Format.format(dt);
  }

  static String formatRelativeDays(DateTime targetDate, [DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = targetDay.difference(refDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${diff.abs()} days overdue';
  }

  static String formatDuration(int days) {
    if (days <= 0) return '0 days';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    final weeks = days ~/ 7;
    final remainingDays = days % 7;
    if (remainingDays == 0) {
      return weeks == 1 ? '1 week' : '$weeks weeks';
    }
    return '$days days ($weeks w ${remainingDays}d)';
  }
}
