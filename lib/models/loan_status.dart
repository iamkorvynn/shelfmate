import 'package:material_ui/material_ui.dart';

enum LoanStatus {
  out('Out'),
  returned('Returned');

  final String displayName;
  const LoanStatus(this.displayName);

  static LoanStatus fromString(String? value) {
    if (value == null) return LoanStatus.out;
    final normalized = value.trim().toLowerCase();
    for (final status in LoanStatus.values) {
      if (status.name.toLowerCase() == normalized ||
          status.displayName.toLowerCase() == normalized) {
        return status;
      }
    }
    return LoanStatus.out;
  }
}

enum DueUrgency {
  overdue('Overdue', Color(0xFFD32F2F), Color(0xFFFFEBEE), Icons.warning_amber_rounded),
  dueToday('Due Today', Color(0xFFE65100), Color(0xFFFFF3E0), Icons.today_rounded),
  dueTomorrow('Due Tomorrow', Color(0xFFF57F17), Color(0xFFFFFDE7), Icons.event_available_rounded),
  dueSoon('Due Soon', Color(0xFF00796B), Color(0xFFE0F2F1), Icons.schedule_rounded),
  onSchedule('On Schedule', Color(0xFF2E7D32), Color(0xFFE8F5E9), Icons.check_circle_outline_rounded),
  returned('Returned', Color(0xFF455A64), Color(0xFFECEFF1), Icons.assignment_turned_in_rounded);

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData icon;

  const DueUrgency(this.label, this.textColor, this.backgroundColor, this.icon);
}
