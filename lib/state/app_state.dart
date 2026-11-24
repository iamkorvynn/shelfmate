// [ShelfMate Dev Step 2/6]: Implement loadInitialData in AppState to populate reactive state
import 'package:material_ui/material_ui.dart';
import '../database/database_service.dart';
import '../models/app_settings.dart';
import '../models/borrower.dart';
import '../models/category.dart';
import '../models/dashboard_stats.dart';
import '../models/item.dart';
import '../models/loan.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/stats_calculator.dart';

class AppState extends ChangeNotifier {
  final DatabaseService databaseService;
  final NotificationService notificationService;
  late final BackupService backupService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  List<Loan> _activeLoans = [];
  List<Loan> get activeLoans => List.unmodifiable(_activeLoans);

  List<Loan> _returnedLoans = [];
  List<Loan> get returnedLoans => List.unmodifiable(_returnedLoans);

  List<Borrower> _borrowers = [];
  List<Borrower> get borrowers => List.unmodifiable(_borrowers);

  List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  DashboardStats _dashboardStats = const DashboardStats();
  DashboardStats get dashboardStats => _dashboardStats;

  AppStats _appStats = const AppStats();
  AppStats get appStats => _appStats;

  AppState({
    DatabaseService? databaseService,
    NotificationService? notificationService,
  })  : databaseService = databaseService ?? DatabaseService(),
        notificationService = notificationService ?? LocalNotificationService() {
    backupService = BackupService(this.databaseService);
  }

  void setNavIndex(int index) {
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await notificationService.initialize();
    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    await _loadData();
    notifyListeners();
  }

  Future<void> _loadData() async {
    _settings = await databaseService.getSettings();
    _borrowers = await databaseService.getAllBorrowers();
    _items = await databaseService.getAllItems();
    _activeLoans = await databaseService.getActiveLoans();
    _returnedLoans = await databaseService.getReturnedLoans();

    final allLoans = await databaseService.getAllLoans();

    _dashboardStats = StatsCalculator.computeDashboardStats(
      activeLoans: _activeLoans,
      totalLoansEver: allLoans.length,
    );

    _appStats = StatsCalculator.computeStats(
      allLoans: allLoans,
      totalBorrowers: _borrowers.length,
      totalItems: _items.length,
    );

    // Schedule notification reminders
    await notificationService.scheduleReminders(_activeLoans, _settings.reminderTime);
  }

  Future<Loan> lendItem({
    int? itemId,
    required String itemName,
    required ItemCategory category,
    String? itemNotes,
    int? borrowerId,
    required String borrowerName,
    String? borrowerPhone,
    required DateTime lentDate,
    required DateTime expectedReturnDate,
    String? loanNotes,
  }) async {
    final loan = await databaseService.lendItem(
      itemId: itemId,
      itemName: itemName,
      category: category,
      itemNotes: itemNotes,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      lentDate: lentDate,
      expectedReturnDate: expectedReturnDate,
      loanNotes: loanNotes,
    );
    await reload();
    return loan;
  }

  Future<void> markReturned(int loanId, DateTime returnDate) async {
    await databaseService.markReturned(loanId, returnDate);
    await reload();
  }

  Future<void> deleteLoan(int loanId) async {
    await databaseService.deleteLoan(loanId);
    await reload();
  }

  Future<int> addBorrower(String name, [String? phone]) async {
    final borrower = Borrower(
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    final id = await databaseService.insertBorrower(borrower);
    await reload();
    return id;
  }

  Future<void> updateBorrower(Borrower borrower) async {
    await databaseService.updateBorrower(borrower);
    await reload();
  }

  Future<void> deleteBorrower(int id) async {
    await databaseService.deleteBorrower(id);
    await reload();
  }

  Future<int> addItem(String name, ItemCategory category, [String? notes]) async {
    final item = Item(
      name: name,
      category: category,
      notes: notes,
      createdAt: DateTime.now(),
    );
    final id = await databaseService.insertItem(item);
    await reload();
    return id;
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await databaseService.saveSettings(newSettings);
    await notificationService.scheduleReminders(_activeLoans, _settings.reminderTime);
    notifyListeners();
  }

  Future<String> exportCsv() async {
    final allLoans = await databaseService.getAllLoans();
    return ExportService.exportLoansToCsv(allLoans);
  }

  Future<String> exportBackupJson() async {
    return await backupService.exportBackupJson();
  }

  Future<bool> restoreBackupJson(String jsonString) async {
    final success = await backupService.restoreFromJsonString(jsonString);
    if (success) {
      await reload();
    }
    return success;
  }

  Future<void> clearAllData() async {
    await databaseService.clearAllData();
    await notificationService.cancelAll();
    await reload();
  }

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);
}
