import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/loan.dart';
import 'package:shelfmate/services/date_formatter.dart';
import 'package:shelfmate/ui/common/category_badge.dart';
import 'package:shelfmate/ui/common/status_badge.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onReturn;
  final VoidCallback? onLendAgain;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const LoanCard({
    super.key,
    required this.loan,
    this.onReturn,
    this.onLendAgain,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = loan.getUrgency();
    final isOut = loan.isOut;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Item name + category badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (loan.itemNotes != null && loan.itemNotes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            loan.itemNotes!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CategoryBadge(category: loan.itemCategory),
                ],
              ),
              const SizedBox(height: 12),

              // Borrower row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF006D77)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loan.borrowerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (loan.borrowerPhone != null && loan.borrowerPhone!.isNotEmpty) ...[
                      Text(
                        loan.borrowerPhone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dates & Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOut ? 'Lent ${DateFormatter.formatDate(loan.lentDate, short: true)}'
                              : 'Out: ${DateFormatter.formatDate(loan.lentDate, short: true)} → ${DateFormatter.formatDate(loan.returnedDate, short: true)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOut
                            ? 'Due: ${DateFormatter.formatDate(loan.expectedReturnDate, short: true)} (${DateFormatter.formatRelativeDays(loan.expectedReturnDate)})'
                            : 'Duration: ${DateFormatter.formatDuration(loan.totalDaysOut())}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOut && loan.isOverdue() ? Colors.red.shade700 : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(urgency: urgency),
                ],
              ),

              if (loan.notes != null && loan.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 14, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loan.notes!,
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDelete != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.grey.shade600,
                      tooltip: 'Delete Loan',
                      onPressed: onDelete,
                    ),
                    const Spacer(),
                  ],
                  if (isOut && onReturn != null)
                    FilledButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                      label: const Text('Mark Returned', style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006D77),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  if (!isOut && onLendAgain != null)
                    OutlinedButton.icon(
                      onPressed: onLendAgain,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Lend Again', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
