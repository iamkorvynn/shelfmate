// [ShelfMate Dev Step 3/4]: Implement scheduleDueTomorrow, scheduleDueToday, scheduleOverdue
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import '../models/loan.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleReminders(List<Loan> activeLoans, TimeOfDay reminderTime);
  Future<void> cancelAll();
  Future<void> showNotification({required int id, required String title, required String body});
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _notifications.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init notice: $e');
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'shelfmate_reminders',
        'Loan Reminders',
        channelDescription: 'Notifications for upcoming and overdue item returns',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );
      await _notifications.show(id, title, body, details);
    } catch (e) {
      debugPrint('Notification show notice: $e');
    }
  }

  @override
  Future<void> scheduleReminders(List<Loan> activeLoans, TimeOfDay reminderTime) async {
    try {
      await cancelAll();
      final now = DateTime.now();

      int notifId = 100;
      for (final loan in activeLoans) {
        if (!loan.isOut) continue;

        // Overdue notification
        if (loan.isOverdue(now)) {
          final daysOverdue = loan.daysOverdue(now);
          await showNotification(
            id: notifId++,
            title: 'Overdue: ${loan.itemName}',
            body: '${loan.borrowerName} was supposed to return this $daysOverdue day${daysOverdue == 1 ? '' : 's'} ago.',
          );
        }
        // Due today notification
        else if (loan.isDueToday(now)) {
          await showNotification(
            id: notifId++,
            title: 'Due Today: ${loan.itemName}',
            body: '${loan.borrowerName} is expected to return this today.',
          );
        }
        // Due tomorrow notification
        else if (loan.isDueTomorrow(now)) {
          await showNotification(
            id: notifId++,
            title: 'Due Tomorrow: ${loan.itemName}',
            body: '${loan.borrowerName} is expected to return this tomorrow.',
          );
        }
      }
    } catch (e) {
      debugPrint('Notification schedule notice: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Notification cancel notice: $e');
    }
  }
}

class MockNotificationService implements NotificationService {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<Map<String, dynamic>> shownNotifications = [];
  bool isInitialized = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
    shownNotifications.clear();
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    shownNotifications.add({'id': id, 'title': title, 'body': body});
  }

  @override
  Future<void> scheduleReminders(List<Loan> activeLoans, TimeOfDay reminderTime) async {
    scheduledNotifications.clear();
    final now = DateTime.now();
    int id = 100;
    for (final loan in activeLoans) {
      if (loan.isOverdue(now)) {
        scheduledNotifications.add({
          'id': id++,
          'type': 'overdue',
          'title': 'Overdue: ${loan.itemName}',
          'body': '${loan.borrowerName} is overdue',
        });
      } else if (loan.isDueToday(now)) {
        scheduledNotifications.add({
          'id': id++,
          'type': 'today',
          'title': 'Due Today: ${loan.itemName}',
          'body': '${loan.borrowerName} is due today',
        });
      } else if (loan.isDueTomorrow(now)) {
        scheduledNotifications.add({
          'id': id++,
          'type': 'tomorrow',
          'title': 'Due Tomorrow: ${loan.itemName}',
          'body': '${loan.borrowerName} is due tomorrow',
        });
      }
    }
  }
}
