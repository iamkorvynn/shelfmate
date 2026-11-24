// [ShelfMate Dev Step 1/3]: Create CSV export confirmation dialog widget
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../services/backup_service.dart';
import '../../../../state/app_state.dart';

class CsvExportDialog extends StatelessWidget {
  final String csvContent;

  const CsvExportDialog({super.key, required this.csvContent});

  static Future<void> show(BuildContext context, String csvContent) {
    return showDialog(
      context: context,
      builder: (ctx) => CsvExportDialog(csvContent: csvContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Export Data (CSV)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Here is your CSV export of all lending records:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csvContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csvContent));
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard!')),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy CSV'),
        ),
      ],
    );
  }
}

class JsonBackupDialog extends StatelessWidget {
  final String jsonContent;

  const JsonBackupDialog({super.key, required this.jsonContent});

  static Future<void> show(BuildContext context, String jsonContent) {
    return showDialog(
      context: context,
      builder: (ctx) => JsonBackupDialog(jsonContent: jsonContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Backup Data (JSON)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full database backup in JSON format. Save this safely to restore later.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: jsonContent));
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy JSON'),
        ),
      ],
    );
  }
}

class JsonRestoreDialog extends StatefulWidget {
  const JsonRestoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const JsonRestoreDialog(),
    );
  }

  @override
  State<JsonRestoreDialog> createState() => _JsonRestoreDialogState();
}

class _JsonRestoreDialogState extends State<JsonRestoreDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Restore Data (JSON)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup JSON below. Warning: restoring will overwrite current data!',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Paste JSON content here...',
                errorText: _errorMessage,
                hintStyle: const TextStyle(fontSize: 12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
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
          onPressed: () async {
            final jsonStr = _controller.text.trim();
            if (jsonStr.isEmpty) {
              setState(() => _errorMessage = 'Please paste backup JSON');
              return;
            }

            if (!BackupService.validateBackupJson(jsonStr)) {
              setState(() => _errorMessage = 'Invalid ShelfMate backup JSON');
              return;
            }

            final success = await appState.restoreBackupJson(jsonStr);
            if (context.mounted) {
              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup restored successfully!')),
                );
              } else {
                setState(() => _errorMessage = 'Failed to restore backup data');
              }
            }
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
