// ============================================================================
// CUSTOM NOTIFICATION TILE
// ============================================================================
// This file is intentionally left blank for your custom implementation.
// You can create your own notification tile widget here.
// ============================================================================

import 'package:flutter/material.dart';

/// Placeholder notification tile for custom implementation
class NotificationTile extends StatelessWidget {
  final String title;
  final String body;

  const NotificationTile({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(body),
      // Add your custom notification tile implementation here
    );
  }
}
