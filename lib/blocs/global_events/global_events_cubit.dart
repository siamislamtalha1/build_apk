import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Bloomee/services/update_notification_service.dart';
import 'package:Bloomee/services/temp_notification_service.dart';

part 'global_events_state.dart';

class GlobalEventsCubit extends Cubit<GlobalEventsState> {
  final _updateService = UpdateNotificationService();
  final _notificationService = TempNotificationService();

  GlobalEventsCubit() : super(GlobalEventsInitial()) {
    checkForUpdates();
    _cleanupOldNotifications();
  }

  void checkForUpdates() async {
    try {
      log('Checking for updates...', name: 'GlobalEventsCubit');

      final updateInfo = await _updateService.checkForUpdates();

      if (updateInfo != null) {
        log('Update available: ${updateInfo.version}',
            name: 'GlobalEventsCubit');

        // Add notification to database
        await _notificationService.addNotification(
          title: 'Update Available',
          body: 'Version ${updateInfo.version} is now available!',
          type: 'update',
          url: updateInfo.releaseUrl,
          payload: updateInfo.releaseNotes,
        );

        // Emit state to show update dialog
        emit(UpdateAvailable(
          newVersion: updateInfo.version,
          message:
              'Version ${updateInfo.version} is now available!\n\n${updateInfo.releaseNotes}',
          downloadUrl: updateInfo.releaseUrl,
        ));
      } else {
        log('No updates available', name: 'GlobalEventsCubit');
      }
    } catch (e) {
      log('Error checking for updates: $e', name: 'GlobalEventsCubit');
    }
  }

  void _cleanupOldNotifications() async {
    try {
      // Clean up notifications older than 7 days
      await _notificationService.clearOldNotifications(daysOld: 7);
    } catch (e) {
      log('Error cleaning up notifications: $e', name: 'GlobalEventsCubit');
    }
  }

  void showAlertDialog(String title, String content) {
    emit(AlertDialogState(title: title, content: content));
  }

  void dismissUpdate() {
    emit(GlobalEventsInitial());
  }
}
