import 'package:material_ui/material_ui.dart';
import '../../../../models/borrower.dart';
import '../../../../state/app_state.dart';

class AddBorrowerDialog extends StatefulWidget {
  final Borrower? existingBorrower;

  const AddBorrowerDialog({super.key, this.existingBorrower});

  static Future<void> show(BuildContext context, {Borrower? existingBorrower}) {
    return showDialog(
      context: context,
      builder: (ctx) => AddBorrowerDialog(existingBorrower: existingBorrower),
    );
  }

  @override
  State<AddBorrowerDialog> createState() => _AddBorrowerDialogState();
}

class _AddBorrowerDialogState extends State<AddBorrowerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingBorrower?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingBorrower?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBorrower != null;
    final appState = AppState.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEditing ? 'Edit Friend' : 'Add Friend'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. Sarah Connor',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: 'e.g. +1 555-0143',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final name = _nameController.text.trim();
            final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();

            if (isEditing) {
              await appState.updateBorrower(
                widget.existingBorrower!.copyWith(name: name, phone: phone),
              );
            } else {
              await appState.addBorrower(name, phone);
            }

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? 'Save Changes' : 'Add Friend'),
        ),
      ],
    );
  }
}
