// [ShelfMate Dev Step 1/2]: Add unit tests for JSON backup export structure
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfmate/services/backup_service.dart';

void main() {
  group('BackupService Validation', () {
    test('validates correct backup JSON structure', () {
      final validJson = jsonEncode({
        'version': 1,
        'exported_at': '2026-11-24T10:00:00',
        'borrowers': [
          {'id': 1, 'name': 'Alice', 'created_at': '2026-11-24'}
        ],
        'items': [
          {'id': 1, 'name': 'Book', 'category': 'Books', 'created_at': '2026-11-24'}
        ],
        'loans': [
          {
            'id': 1,
            'item_id': 1,
            'borrower_id': 1,
            'lent_date': '2026-11-20',
            'expected_return_date': '2026-11-27',
            'status': 'out',
            'created_at': '2026-11-20'
          }
        ],
        'app_settings': [
          {'key': 'default_loan_period_days', 'value': '14'}
        ],
      });

      expect(BackupService.validateBackupJson(validJson), isTrue);
    });

    test('rejects malformed or invalid JSON strings', () {
      expect(BackupService.validateBackupJson('not a json'), isFalse);
      expect(BackupService.validateBackupJson(''), isFalse);
      expect(BackupService.validateBackupJson('{invalid}'), isFalse);
      expect(BackupService.validateBackupJson('[1, 2, 3]'), isFalse);
    });

    test('rejects JSON missing required tables', () {
      expect(
        BackupService.validateBackupJson(jsonEncode({'items': []})),
        isFalse,
      );
      expect(
        BackupService.validateBackupJson(jsonEncode({'borrowers': [], 'items': []})),
        isFalse,
      );
      expect(
        BackupService.validateBackupJson(jsonEncode({'loans': []})),
        isFalse,
      );
    });
  });
}
