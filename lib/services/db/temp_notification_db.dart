import 'package:isar_community/isar.dart';

part 'temp_notification_db.g.dart';

@collection
class NotificationDB {
  Id? id = Isar.autoIncrement;

  late String title;
  late String body;
  late String type;
  DateTime? time;
  String? url;
  String? payload;

  NotificationDB();
}
