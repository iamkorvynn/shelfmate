// [ShelfMate Dev Step 1/3]: Create BorrowerDetailScreen structure and contact header
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/common/confirm_dialog.dart';
import 'package:shelfmate/ui/screens/items/lend_item_sheet.dart';
import 'package:shelfmate/ui/screens/items/mark_returned_dialog.dart';
import 'package:shelfmate/ui/screens/items/widgets/loan_card.dart';
import 'widgets/add_borrower_dialog.dart';

class BorrowerDetailScreen extends StatelessWidget {
  final int borrowerId;

  const BorrowerDetailScreen({super.key, required this.borrowerId});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final borrowers = appState.borrowers.where((b) => b.id == borrowerId).toList();

    if (borrowers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend Details')),
        body: const Center(child: Text('Friend not found')),
      );
    }

    final borrower = borrowers.first;
    final activeLoans = appState.activeLoans.where((l) => l.borrowerId == borrower.id).toList();
    final returnedLoans = appState.returnedLoans.where((l) => l.borrowerId == borrower.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(borrower.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Friend',
            onPressed: () => AddBorrowerDialog.show(context, existingBorrower: borrower),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Friend',
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context: context,
                title: 'Delete Friend',
                message:
                    'Are you sure you want to delete ${borrower.name}? Any loans associated with this friend will also be deleted.',
                isDestructive: true,
              );
              if (confirm) {
                await appState.deleteBorrower(borrower.id!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF006D77).withValues(alpha: 0.12),
                    child: Text(
                      borrower.name.isNotEmpty ? borrower.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006D77),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          borrower.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (borrower.phone != null && borrower.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                borrower.phone!,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeLoans.isNotEmpty
                                    ? Colors.amber.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${activeLoans.length} Out Now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activeLoans.isNotEmpty
                                      ? Colors.amber.shade900
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${activeLoans.length + returnedLoans.length} total loans',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Currently Out Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Currently Borrowed (${activeLoans.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            if (activeLoans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No items currently borrowed by ${borrower.name}.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ...activeLoans.map((loan) {
                return LoanCard(
                  loan: loan,
                  onReturn: () async {
                    final returnDate = await MarkReturnedDialog.show(context, loan);
                    if (returnDate != null) {
                      await appState.markReturned(loan.id!, returnDate);
                    }
                  },
                );
              }),

            const SizedBox(height: 16),

            // Borrowing History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Borrowing History (${returnedLoans.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            if (returnedLoans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No past returned loans for ${borrower.name}.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ...returnedLoans.map((loan) {
                return LoanCard(
                  loan: loan,
                  onLendAgain: () {
                    LendItemSheet.show(
                      context,
                      preselectedBorrower: borrower,
                      initialItemName: loan.itemName,
                      initialCategory: loan.itemCategory,
                    );
                  },
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          LendItemSheet.show(
            context,
            preselectedBorrower: borrower,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Lend to Friend'),
      ),
    );
  }
}
