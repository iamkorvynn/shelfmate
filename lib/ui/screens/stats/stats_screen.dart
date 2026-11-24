import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/services/date_formatter.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/common/category_badge.dart';
import 'package:shelfmate/ui/common/empty_state_view.dart';
import 'package:shelfmate/ui/screens/items/lend_item_sheet.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final stats = appState.appStats;

    if (appState.dashboardStats.totalLentEver == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lending Statistics')),
        body: EmptyStateView(
          icon: Icons.bar_chart_rounded,
          title: 'No Stats Yet',
          message: 'Lend some items to see stats like most-borrowed items, top borrowers, and return rates.',
          buttonText: 'Lend an Item',
          onButtonPressed: () => LendItemSheet.show(context),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lending Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Metrics: On-time Return Rate Banner
            _buildOnTimeRateCard(context, stats),
            const SizedBox(height: 16),

            // Highlights Grid (Most Borrowed, Most Frequent, Longest Outstanding)
            const Text(
              'Lending Highlights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),

            _buildHighlightTile(
              icon: Icons.star_rounded,
              iconColor: Colors.amber.shade800,
              title: 'Most-Borrowed Item',
              mainText: stats.mostBorrowedItemName ?? 'None',
              subText: stats.mostBorrowedItemCount > 0
                  ? 'Borrowed ${stats.mostBorrowedItemCount} time${stats.mostBorrowedItemCount == 1 ? '' : 's'}'
                  : 'No loans yet',
            ),
            const SizedBox(height: 8),

            _buildHighlightTile(
              icon: Icons.person_pin_rounded,
              iconColor: const Color(0xFF006D77),
              title: 'Most Frequent Borrower',
              mainText: stats.mostFrequentBorrowerName ?? 'None',
              subText: stats.mostFrequentBorrowerCount > 0
                  ? 'Borrowed ${stats.mostFrequentBorrowerCount} time${stats.mostFrequentBorrowerCount == 1 ? '' : 's'}'
                  : 'No loans yet',
            ),
            const SizedBox(height: 8),

            _buildHighlightTile(
              icon: Icons.timelapse_rounded,
              iconColor: const Color(0xFFE29578),
              title: 'Longest Outstanding Loan',
              mainText: stats.longestOutstandingLoan != null
                  ? stats.longestOutstandingLoan!.itemName
                  : 'None',
              subText: stats.longestOutstandingLoan != null
                  ? 'With ${stats.longestOutstandingLoan!.borrowerName} (${DateFormatter.formatDuration(stats.longestOutstandingDays)})'
                  : 'No active loans out',
            ),
            const SizedBox(height: 20),

            // Loans Per Category Breakdown
            const Text(
              'Loans per Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),
            _buildCategoryBreakdownCard(context, stats),
            const SizedBox(height: 20),

            // Summary Stats Card
            const Text(
              'General Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),
            _buildGeneralSummaryCard(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildOnTimeRateCard(BuildContext context, dynamic stats) {
    final rate = stats.onTimeReturnRate as double;
    final totalReturned = stats.totalReturnedCount as int;
    final onTimeCount = stats.onTimeReturnedCount as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ON-TIME RETURN RATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF006D77),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Reliability of returns',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006D77),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalReturned > 0 ? rate / 100.0 : 1.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 80 ? const Color(0xFF2E7D32) : (rate >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            totalReturned > 0
                ? '$onTimeCount of $totalReturned returned items came back on or before due date'
                : 'No returned items yet to compute return rate',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String mainText,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  mainText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(BuildContext context, dynamic stats) {
    final Map<ItemCategory, int> categoryCounts = stats.loansPerCategory;
    final totalLoans = categoryCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: ItemCategory.values.map((cat) {
          final count = categoryCounts[cat] ?? 0;
          final pct = totalLoans > 0 ? (count / totalLoans) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CategoryBadge(category: cat),
                    Text(
                      '$count loan${count == 1 ? '' : 's'} (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGeneralSummaryCard(BuildContext context, dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'Average Loan Duration',
            value: DateFormatter.formatDuration((stats.averageLoanDurationDays as double).round()),
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Registered Friends',
            value: stats.totalUniqueBorrowers.toString(),
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Cataloged Items',
            value: stats.totalUniqueItems.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
