// [ShelfMate Dev Step 1/2]: Create ExportService class with CSV headers definition
import '../models/loan.dart';
import 'date_formatter.dart';

class ExportService {
  static String exportLoansToCsv(List<Loan> loans, [DateTime? referenceDate]) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'ID,Item Name,Category,Borrower,Phone,Date Lent,Expected Return,Date Returned,Status,Days Out,Notes',
    );

    for (final loan in loans) {
      final daysOut = loan.totalDaysOut(referenceDate);
      final fields = [
        loan.id?.toString() ?? '',
        _escapeCsv(loan.itemName),
        _escapeCsv(loan.itemCategory.displayName),
        _escapeCsv(loan.borrowerName),
        _escapeCsv(loan.borrowerPhone ?? ''),
        DateFormatter.formatIsoDate(loan.lentDate),
        DateFormatter.formatIsoDate(loan.expectedReturnDate),
        loan.returnedDate != null ? DateFormatter.formatIsoDate(loan.returnedDate!) : '',
        loan.status.displayName,
        daysOut.toString(),
        _escapeCsv(loan.notes ?? ''),
      ];
      buffer.writeln(fields.join(','));
    }

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      final replaced = value.replaceAll('"', '""');
      return '"$replaced"';
    }
    return value;
  }
}
