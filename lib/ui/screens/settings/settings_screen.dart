import 'package:material_ui/material_ui.dart';
import 'package:shelfmate/services/date_formatter.dart';
import 'package:shelfmate/state/app_state.dart';
import 'package:shelfmate/ui/common/confirm_dialog.dart';
import 'widgets/data_dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Preferences Section
            _buildSectionHeader('LOAN PREFERENCES'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.date_range_rounded, color: Color(0xFF006D77)),
                    title: const Text('Default Loan Period'),
                    subtitle: Text(
                      '${settings.defaultLoanPeriodDays} days',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF006D77)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Slider(
                      value: settings.defaultLoanPeriodDays.toDouble().clamp(1.0, 90.0),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '${settings.defaultLoanPeriodDays} days',
                      activeColor: const Color(0xFF006D77),
                      onChanged: (val) {
                        appState.updateSettings(
                          settings.copyWith(defaultLoanPeriodDays: val.round()),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded, color: Color(0xFF006D77)),
                    title: const Text('Daily Reminder Time'),
                    subtitle: Text(
                      DateFormatter.formatTime(
                        settings.reminderTime,
                        use24Hour: settings.use24HourClock,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF006D77)),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settings.reminderTime,
                      );
                      if (picked != null) {
                        await appState.updateSettings(
                          settings.copyWith(
                            reminderHour: picked.hour,
                            reminderMinute: picked.minute,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.schedule_rounded, color: Color(0xFF006D77)),
                    title: const Text('24-Hour Clock'),
                    subtitle: Text(settings.use24HourClock ? '24-hour format' : '12-hour AM/PM format'),
                    value: settings.use24HourClock,
                    activeThumbColor: const Color(0xFF006D77),
                    onChanged: (val) {
                      appState.updateSettings(
                        settings.copyWith(use24HourClock: val),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data Management Section
            _buildSectionHeader('DATA & BACKUP'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.table_chart_rounded, color: Color(0xFF006D77)),
                    title: const Text('Export Data (CSV)'),
                    subtitle: const Text('Export all loan history to CSV format'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final csv = await appState.exportCsv();
                      if (context.mounted) {
                        CsvExportDialog.show(context, csv);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download_rounded, color: Color(0xFF006D77)),
                    title: const Text('Backup Data (JSON)'),
                    subtitle: const Text('Generate a complete database backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final json = await appState.exportBackupJson();
                      if (context.mounted) {
                        JsonBackupDialog.show(context, json);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF006D77)),
                    title: const Text('Restore Data (JSON)'),
                    subtitle: const Text('Import and restore from a JSON backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      JsonRestoreDialog.show(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
                    title: Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Permanently delete all items, borrowers, and loans'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final confirm = await ConfirmDialog.show(
                        context: context,
                        title: 'Clear All Data?',
                        message:
                            'This will permanently delete all friends, items, loans, and reset settings. The app will return to an empty state.\n\nThis cannot be undone.',
                        confirmText: 'Delete Everything',
                        isDestructive: true,
                      );
                      if (confirm) {
                        await appState.clearAllData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All data cleared successfully.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            _buildSectionHeader('ABOUT SHELFMATE'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006D77).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF006D77), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ShelfMate',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Personal Lending Tracker',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"What did I lend, to whom, and when is it coming back?"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '100% offline & local. No accounts, no cloud, no analytics.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(0xFF006D77),
        ),
      ),
    );
  }
}
