import 'package:material_ui/material_ui.dart';
import '../../models/loan_status.dart';

class StatusBadge extends StatelessWidget {
  final DueUrgency urgency;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.urgency,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgency.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgency.textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(urgency.icon, size: 14, color: urgency.textColor),
          const SizedBox(width: 4),
          Text(
            customLabel ?? urgency.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: urgency.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
