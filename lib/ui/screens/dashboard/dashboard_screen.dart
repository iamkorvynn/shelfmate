// [ShelfMate Dev Step 2/3]: Add Next Due section and recent loans list in DashboardScreen
import 'package:material_ui/material_ui.dart';
import '../../../state/app_state.dart';
import '../../common/empty_state_view.dart';
import '../../common/metric_card.dart';
import '../items/lend_item_sheet.dart';
import '../items/mark_returned_dialog.dart';
import '../items/widgets/loan_card.dart';
import 'widgets/next_due_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final stats = appState.dashboardStats;
    final activeLoans = appState.activeLoans;

    if (appState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stats.totalLentEver == 0 && activeLoans.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ShelfMate'),
        ),
        body: EmptyStateView(
          icon: Icons.menu_book_rounded,
          title: 'Welcome to ShelfMate',
          message:
              'Track what you lend, to whom, and when it is coming back.\nStart by lending your first item!',
          buttonText: 'Lend an Item',
          onButtonPressed: () => LendItemSheet.show(context),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfMate'),
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Next due item highlight
              NextDueCard(
                loan: stats.nextItemDueBack,
                onReturn: stats.nextItemDueBack != null
                    ? () async {
                        final returnDate = await MarkReturnedDialog.show(
                          context,
                          stats.nextItemDueBack!,
                        );
                        if (returnDate != null) {
                          await appState.markReturned(
                            stats.nextItemDueBack!.id!,
                            returnDate,
                          );
                        }
                      }
                    : null,
              ),

              // 2x2 Metrics Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Out Now',
                            value: stats.outNow.toString(),
                            icon: Icons.outbox_rounded,
                            color: const Color(0xFF006D77),
                            subtitle: 'Currently with friends',
                            onTap: () => appState.setNavIndex(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            title: 'Due Soon',
                            value: stats.dueSoon.toString(),
                            icon: Icons.schedule_rounded,
                            color: const Color(0xFFE65100),
                            subtitle: 'Within 2 days',
                            onTap: () => appState.setNavIndex(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Overdue',
                            value: stats.overdue.toString(),
                            icon: Icons.warning_amber_rounded,
                            color: stats.overdue > 0 ? Colors.red.shade700 : Colors.grey.shade600,
                            subtitle: stats.overdue > 0 ? 'Needs return!' : 'All on time',
                            onTap: () => appState.setNavIndex(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            title: 'Total Lent Ever',
                            value: stats.totalLentEver.toString(),
                            icon: Icons.history_rounded,
                            color: const Color(0xFF455A64),
                            subtitle: 'All-time loans',
                            onTap: () => appState.setNavIndex(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active Loans Section
              if (activeLoans.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Loans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => appState.setNavIndex(1),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                ...activeLoans.take(5).map((loan) {
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
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LendItemSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Lend Item'),
      ),
    );
  }
}
