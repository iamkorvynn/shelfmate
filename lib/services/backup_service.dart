// [ShelfMate Dev Step 2/3]: Implement exportBackupToJson in BackupService
import 'dart:convert';
import '../database/database_service.dart';

class BackupService {
  final DatabaseService databaseService;

  BackupService(this.databaseService);

  Future<String> exportBackupJson() async {
    final data = await databaseService.exportAllData();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<bool> restoreFromJsonString(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      return await databaseService.restoreAllData(decoded);
    } catch (_) {
      return false;
    }
  }

  static bool validateBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return false;
      if (!decoded.containsKey('borrowers') ||
          !decoded.containsKey('items') ||
          !decoded.containsKey('loans')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
