import 'dart:async';
import 'dart:developer';

import 'package:Bloomee/model/notification_model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial()) {
    getNotification();
  }
  void getNotification() async {
    // Legacy DB notifications removed.
    // Return empty list or fetch from new source if implemented.
    List<NotificationModel> notifications = [];
    emit(NotificationState(notifications: notifications));
  }

  void clearNotification() {
    log("Notification Cleared");
    getNotification();
  }

  Future<void> watchNotification() async {
    // Watcher removed
  }

}
