import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/borrower.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/common/empty_state_view.dart';
import 'borrower_detail_screen.dart';
import 'widgets/add_borrower_dialog.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Borrower> _filterBorrowers(List<Borrower> borrowers) {
    if (_searchQuery.isEmpty) return borrowers;
    return borrowers.where((b) {
      final nameMatch = b.name.toLowerCase().contains(_searchQuery);
      final phoneMatch = b.phone?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatch || phoneMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final borrowers = _filterBorrowers(appState.borrowers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Borrowers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends by name or phone...',
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
          Expanded(
            child: borrowers.isEmpty
                ? EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: _searchQuery.isNotEmpty ? 'No matching friends' : 'No friends added yet',
                    message: _searchQuery.isNotEmpty
                        ? 'Try a different search term.'
                        : 'Keep a record of your friends so you can track what they borrow.',
                    buttonText: _searchQuery.isEmpty ? 'Add Friend' : null,
                    onButtonPressed: () => AddBorrowerDialog.show(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: borrowers.length,
                    itemBuilder: (ctx, index) {
                      final borrower = borrowers[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF006D77).withValues(alpha: 0.12),
                            child: Text(
                              borrower.name.isNotEmpty ? borrower.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006D77),
                              ),
                            ),
                          ),
                          title: Text(
                            borrower.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (borrower.phone != null && borrower.phone!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  borrower.phone!,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (borrower.activeLoansCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${borrower.activeLoansCount} Out',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '0 Out',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${borrower.totalLoansCount} total',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => BorrowerDetailScreen(
                                  borrowerId: borrower.id!,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddBorrowerDialog.show(context),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
