// [ShelfMate Dev Step 2/4]: Add item name, category selection, and notes to LendItemSheet
import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/models/borrower.dart';
import 'package:shelfmate/models/category.dart';
import 'package:shelfmate/models/item.dart';
import 'package:shelfmate/services/date_formatter.dart';
import 'package:shelfmate/state/app_state.dart';

class LendItemSheet extends StatefulWidget {
  final Item? preselectedItem;
  final Borrower? preselectedBorrower;
  final String? initialItemName;
  final ItemCategory? initialCategory;

  const LendItemSheet({
    super.key,
    this.preselectedItem,
    this.preselectedBorrower,
    this.initialItemName,
    this.initialCategory,
  });

  static Future<void> show(
    BuildContext context, {
    Item? preselectedItem,
    Borrower? preselectedBorrower,
    String? initialItemName,
    ItemCategory? initialCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LendItemSheet(
        preselectedItem: preselectedItem,
        preselectedBorrower: preselectedBorrower,
        initialItemName: initialItemName,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<LendItemSheet> createState() => _LendItemSheetState();
}

class _LendItemSheetState extends State<LendItemSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late TextEditingController _itemNotesController;
  late TextEditingController _borrowerNameController;
  late TextEditingController _borrowerPhoneController;
  late TextEditingController _loanNotesController;

  late ItemCategory _selectedCategory;
  late DateTime _lentDate;
  late DateTime _expectedReturnDate;

  int? _selectedItemId;
  int? _selectedBorrowerId;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(
      text: widget.preselectedItem?.name ?? widget.initialItemName ?? '',
    );
    _itemNotesController = TextEditingController(
      text: widget.preselectedItem?.notes ?? '',
    );
    _borrowerNameController = TextEditingController(
      text: widget.preselectedBorrower?.name ?? '',
    );
    _borrowerPhoneController = TextEditingController(
      text: widget.preselectedBorrower?.phone ?? '',
    );
    _loanNotesController = TextEditingController();

    _selectedCategory = widget.preselectedItem?.category ??
        widget.initialCategory ??
        ItemCategory.books;
    _selectedItemId = widget.preselectedItem?.id;
    _selectedBorrowerId = widget.preselectedBorrower?.id;

    _lentDate = DateTime.now();
    _expectedReturnDate = DateTime.now().add(const Duration(days: 14));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppState.of(context);
    final defaultDays = appState.settings.defaultLoanPeriodDays;
    _expectedReturnDate = _lentDate.add(Duration(days: defaultDays));
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNotesController.dispose();
    _borrowerNameController.dispose();
    _borrowerPhoneController.dispose();
    _loanNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final appState = AppState.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lend an Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Item Section
              const Text(
                'ITEM DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF006D77),
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Physics Textbook, USB-C Cable',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ItemCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ItemCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (cat) {
                  if (cat != null) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _itemNotesController,
                decoration: const InputDecoration(
                  labelText: 'Item Note (optional)',
                  hintText: 'e.g. Blue cover, 65W fast charger',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Borrower Section
              const Text(
                'BORROWER (FRIEND)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF006D77),
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _borrowerNameController,
                decoration: const InputDecoration(
                  labelText: "Friend's Name *",
                  hintText: 'e.g. Alex Smith',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter the friend's name";
                  }
                  return null;
                },
              ),

              if (appState.borrowers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: appState.borrowers.map((b) {
                    return ActionChip(
                      avatar: const Icon(Icons.person, size: 14),
                      label: Text(b.name, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _selectedBorrowerId = b.id;
                          _borrowerNameController.text = b.name;
                          if (b.phone != null && b.phone!.isNotEmpty) {
                            _borrowerPhoneController.text = b.phone!;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),

              TextFormField(
                controller: _borrowerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: 'e.g. +1 555-0199',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Loan Dates Section
              const Text(
                'LOAN DATES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF006D77),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _lentDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _lentDate = picked;
                            if (_expectedReturnDate.isBefore(_lentDate)) {
                              _expectedReturnDate = _lentDate.add(
                                Duration(days: appState.settings.defaultLoanPeriodDays),
                              );
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Lent',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF006D77)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormatter.formatDate(_lentDate, short: true),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expectedReturnDate,
                          firstDate: _lentDate,
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setState(() {
                            _expectedReturnDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expected Return',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event_available, size: 16, color: Color(0xFF006D77)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormatter.formatDate(_expectedReturnDate, short: true),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _loanNotesController,
                decoration: const InputDecoration(
                  labelText: 'Loan Note (optional)',
                  hintText: 'e.g. Needs it for semester project',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    await appState.lendItem(
                      itemId: _selectedItemId,
                      itemName: _itemNameController.text.trim(),
                      category: _selectedCategory,
                      itemNotes: _itemNotesController.text.trim(),
                      borrowerId: _selectedBorrowerId,
                      borrowerName: _borrowerNameController.text.trim(),
                      borrowerPhone: _borrowerPhoneController.text.trim(),
                      lentDate: _lentDate,
                      expectedReturnDate: _expectedReturnDate,
                      loanNotes: _loanNotesController.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lent "${_itemNameController.text}" to ${_borrowerNameController.text}!'),
                          backgroundColor: const Color(0xFF006D77),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Lend Item Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
