import 'package:material_ui/material_ui.dart';
import '../../../models/category.dart';
import '../../../models/loan.dart';
import '../../../state/app_state.dart';
import '../../common/confirm_dialog.dart';
import '../../common/empty_state_view.dart';
import 'lend_item_sheet.dart';
import 'mark_returned_dialog.dart';
import 'widgets/loan_card.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ItemCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Loan> _filterLoans(List<Loan> loans) {
    return loans.where((loan) {
      if (_selectedCategory != null && loan.itemCategory != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchItem = loan.itemName.toLowerCase().contains(_searchQuery);
        final matchBorrower = loan.borrowerName.toLowerCase().contains(_searchQuery);
        final matchNotes = loan.notes?.toLowerCase().contains(_searchQuery) ?? false;
        if (!matchItem && !matchBorrower && !matchNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final filteredActive = _filterLoans(appState.activeLoans);
    final filteredReturned = _filterLoans(appState.returnedLoans);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Tracker'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF006D77),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF006D77),
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: 'Out (${appState.activeLoans.length})',
              icon: const Icon(Icons.outbox_rounded),
            ),
            Tab(
              text: 'Returned (${appState.returnedLoans.length})',
              icon: const Icon(Icons.assignment_turned_in_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Category Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items, borrowers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...ItemCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Out Tab
                _buildActiveTab(context, appState, filteredActive),
                // Returned Tab (History)
                _buildReturnedTab(context, appState, filteredReturned),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => LendItemSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveTab(
    BuildContext context,
    AppState appState,
    List<Loan> loans,
  ) {
    if (loans.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'No matching items'
            : 'No items currently out',
        message: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'Try adjusting your search or category filter.'
            : 'Everything you own is in your possession.\nLend an item to start tracking!',
        buttonText: _searchQuery.isEmpty && _selectedCategory == null ? 'Lend Item' : null,
        onButtonPressed: () => LendItemSheet.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: loans.length,
      itemBuilder: (ctx, index) {
        final loan = loans[index];
        return LoanCard(
          loan: loan,
          onReturn: () async {
            final returnDate = await MarkReturnedDialog.show(context, loan);
            if (returnDate != null) {
              await appState.markReturned(loan.id!, returnDate);
            }
          },
          onDelete: () async {
            final confirm = await ConfirmDialog.show(
              context: context,
              title: 'Delete Loan',
              message: 'Are you sure you want to delete this loan record for "${loan.itemName}"?',
              isDestructive: true,
            );
            if (confirm) {
              await appState.deleteLoan(loan.id!);
            }
          },
        );
      },
    );
  }

  Widget _buildReturnedTab(
    BuildContext context,
    AppState appState,
    List<Loan> loans,
  ) {
    if (loans.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_rounded,
        title: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'No matching history'
            : 'No returned items yet',
        message: _searchQuery.isNotEmpty || _selectedCategory != null
            ? 'Try adjusting your search or category filter.'
            : 'Items returned by friends will appear here with loan duration and dates.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: loans.length,
      itemBuilder: (ctx, index) {
        final loan = loans[index];
        return LoanCard(
          loan: loan,
          onLendAgain: () {
            LendItemSheet.show(
              context,
              initialItemName: loan.itemName,
              initialCategory: loan.itemCategory,
            );
          },
          onDelete: () async {
            final confirm = await ConfirmDialog.show(
              context: context,
              title: 'Delete Record',
              message: 'Are you sure you want to delete this history record for "${loan.itemName}"?',
              isDestructive: true,
            );
            if (confirm) {
              await appState.deleteLoan(loan.id!);
            }
          },
        );
      },
    );
  }
}
