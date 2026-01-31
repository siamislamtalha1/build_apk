import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/temp_notification_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display temporary notification banners
class NotificationBannerWidget extends StatefulWidget {
  const NotificationBannerWidget({super.key});

  @override
  State<NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<NotificationBannerWidget> {
  final _notificationService = TempNotificationService();
  List<NotificationDB> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationService.getActiveNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _notifications.map((notification) {
        return _buildNotificationBanner(notification);
      }).toList(),
    );
  }

  Widget _buildNotificationBanner(NotificationDB notification) {
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Default_Theme.primaryTextStyle.merge(
                          TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Default_Theme.primaryColor1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Default_Theme.secondoryTextStyle.merge(
                          TextStyle(
                            fontSize: 12,
                            color: Default_Theme.primaryColor2,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                IconButton(
                  icon: const Icon(MingCute.close_line),
                  color: Default_Theme.primaryColor2,
                  iconSize: 20,
                  onPressed: () => _dismissNotification(notification),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'update':
        return MingCute.download_2_fill;
      case 'info':
        return MingCute.information_fill;
      case 'warning':
        return MingCute.alert_fill;
      case 'success':
        return MingCute.check_circle_fill;
      case 'error':
        return MingCute.close_circle_fill;
      default:
        return MingCute.notification_fill;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'update':
        return Default_Theme.accentColor2;
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Default_Theme.primaryColor1;
    }
  }

  Future<void> _handleNotificationTap(NotificationDB notification) async {
    if (notification.url != null && notification.url!.isNotEmpty) {
      try {
        final uri = Uri.parse(notification.url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('Failed to open URL: $e');
      }
    }
  }

  Future<void> _dismissNotification(NotificationDB notification) async {
    if (notification.id != null) {
      await _notificationService.removeNotification(notification.id!);
      await _loadNotifications();
    }
  }
}
