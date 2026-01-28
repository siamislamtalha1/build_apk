import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing onboarding and first-launch detection
class OnboardingService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyInstallDate = 'install_date';
  static const String _keyLastLoginReminder = 'last_login_reminder';
  static const String _keyHasSeenLogin = 'has_seen_login';

  /// Check if this is the first launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_keyFirstLaunch) ?? true;

    if (isFirst) {
      // Mark as not first launch and save install date
      await prefs.setBool(_keyFirstLaunch, false);
      await prefs.setInt(
          _keyInstallDate, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_keyHasSeenLogin, true);
    }

    return isFirst;
  }

  /// Check if user has seen the login screen
  static Future<bool> hasSeenLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenLogin) ?? false;
  }

  /// Mark that user has seen the login screen
  static Future<void> markLoginSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenLogin, true);
  }

  /// Check if we should show weekly login reminder
  /// Shows reminder every 7 days after installation for guest users
  static Future<bool> shouldShowWeeklyReminder() async {
    final prefs = await SharedPreferences.getInstance();

    // Get install date
    final installDate = prefs.getInt(_keyInstallDate);
    if (installDate == null) return false;

    // Get last reminder date
    final lastReminder = prefs.getInt(_keyLastLoginReminder) ?? installDate;

    // Calculate days since last reminder
    final now = DateTime.now();
    final lastReminderDate = DateTime.fromMillisecondsSinceEpoch(lastReminder);
    final daysSinceLastReminder = now.difference(lastReminderDate).inDays;

    // Show reminder if 7 days have passed
    if (daysSinceLastReminder >= 7) {
      // Update last reminder date
      await prefs.setInt(_keyLastLoginReminder, now.millisecondsSinceEpoch);
      return true;
    }

    return false;
  }

  /// Get days since installation
  static Future<int> getDaysSinceInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final installDate = prefs.getInt(_keyInstallDate);

    if (installDate == null) return 0;

    final now = DateTime.now();
    final install = DateTime.fromMillisecondsSinceEpoch(installDate);
    return now.difference(install).inDays;
  }

  /// Reset onboarding (for testing)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyInstallDate);
    await prefs.remove(_keyLastLoginReminder);
    await prefs.remove(_keyHasSeenLogin);
  }
}
