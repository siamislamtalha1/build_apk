import 'dart:developer';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:isar_community/isar.dart';

/// Service to manage temporary in-app notifications
class TempNotificationService {
  static final TempNotificationService _instance =
      TempNotificationService._internal();
  factory TempNotificationService() => _instance;
  TempNotificationService._internal();

  /// Add a notification to the database
  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
    String? url,
    String? payload,
    DateTime? time,
  }) async {
    try {
      final isar = await BloomeeDBService.db;
      final notification = NotificationDB()
        ..title = title
        ..body = body
        ..type = type
        ..time = time ?? DateTime.now()
        ..url = url
        ..payload = payload;

      await isar.writeTxn(() async {
        await isar.notificationDBs.put(notification);
      });

      log('Notification added: $title', name: 'TempNotificationService');
    } catch (e) {
      log('Failed to add notification: $e', name: 'TempNotificationService');
    }
  }

  /// Get all active notifications
  Future<List<NotificationDB>> getActiveNotifications() async {
    try {
      final isar = await BloomeeDBService.db;
      final notifications =
          await isar.notificationDBs.where().sortByTimeDesc().findAll();

      return notifications;
    } catch (e) {
      log('Failed to get notifications: $e', name: 'TempNotificationService');
      return [];
    }
  }

  /// Get notifications by type
  Future<List<NotificationDB>> getNotificationsByType(String type) async {
    try {
      final isar = await BloomeeDBService.db;
      final notifications = await isar.notificationDBs
          .filter()
          .typeEqualTo(type)
          .sortByTimeDesc()
          .findAll();

      return notifications;
    } catch (e) {
      log('Failed to get notifications by type: $e',
          name: 'TempNotificationService');
      return [];
    }
  }

  /// Remove a notification by ID
  Future<void> removeNotification(Id id) async {
    try {
      final isar = await BloomeeDBService.db;
      await isar.writeTxn(() async {
        await isar.notificationDBs.delete(id);
      });

      log('Notification removed: $id', name: 'TempNotificationService');
    } catch (e) {
      log('Failed to remove notification: $e', name: 'TempNotificationService');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final isar = await BloomeeDBService.db;
      await isar.writeTxn(() async {
        await isar.notificationDBs.clear();
      });

      log('All notifications cleared', name: 'TempNotificationService');
    } catch (e) {
      log('Failed to clear notifications: $e', name: 'TempNotificationService');
    }
  }

  /// Clear notifications older than specified days
  Future<void> clearOldNotifications({int daysOld = 7}) async {
    try {
      final isar = await BloomeeDBService.db;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldNotifications = await isar.notificationDBs
          .filter()
          .timeLessThan(cutoffDate)
          .findAll();

      if (oldNotifications.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.notificationDBs.deleteAll(
            oldNotifications.map((n) => n.id!).toList(),
          );
        });

        log('Cleared ${oldNotifications.length} old notifications',
            name: 'TempNotificationService');
      }
    } catch (e) {
      log('Failed to clear old notifications: $e',
          name: 'TempNotificationService');
    }
  }

  /// Watch for notification changes
  Stream<void> watchNotifications() async* {
    final isar = await BloomeeDBService.db;
    yield* isar.notificationDBs.watchLazy();
  }
}
