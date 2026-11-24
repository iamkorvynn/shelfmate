// [ShelfMate Dev Step 1/2]: Create MarkReturnedDialog widget structure
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/services/date_formatter.dart';

class MarkReturnedDialog extends StatefulWidget {
  final Loan loan;

  const MarkReturnedDialog({super.key, required this.loan});

  static Future<DateTime?> show(BuildContext context, Loan loan) {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => MarkReturnedDialog(loan: loan),
    );
  }

  @override
  State<MarkReturnedDialog> createState() => _MarkReturnedDialogState();
}

class _MarkReturnedDialogState extends State<MarkReturnedDialog> {
  late DateTime _returnDate;

  @override
  void initState() {
    super.initState();
    _returnDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark as Returned', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${widget.loan.itemName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Borrower: ${widget.loan.borrowerName}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Return Date:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _returnDate,
                  firstDate: widget.loan.lentDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _returnDate = picked;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF006D77)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormatter.formatDate(_returnDate),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_returnDate),
          child: const Text('Confirm Return'),
        ),
      ],
    );
  }
}
