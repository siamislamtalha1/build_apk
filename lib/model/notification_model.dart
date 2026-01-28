class NotificationModel {
  String title;
  String body;
  String type;
  String? url;
  String? payload;
  DateTime? time;

  NotificationModel({
    required this.title,
    required this.body,
    required this.type,
    this.time,
    this.url,
    this.payload,
  });
}
