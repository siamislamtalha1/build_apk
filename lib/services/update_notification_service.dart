import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';

/// Service to check for app updates from GitHub releases
class UpdateNotificationService {
  static final UpdateNotificationService _instance =
      UpdateNotificationService._internal();
  factory UpdateNotificationService() => _instance;
  UpdateNotificationService._internal();

  // GitHub repository details
  static const String _repoOwner = 'HemantKArya';
  static const String _repoName = 'BloomeeTunes';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Check if updates are available
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Check if user has enabled auto-update notifications
      final autoUpdateEnabled = await BloomeeDBService.getSettingBool(
        GlobalStrConsts.autoUpdateNotify,
        defaultValue: true,
      );

      if (autoUpdateEnabled == false) {
        log('Auto-update notifications disabled', name: 'UpdateService');
        return null;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final releaseUrl = data['html_url'] as String;
        final releaseNotes = data['body'] as String? ?? '';

        // Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          log('Update available: $latestVersion (current: $currentVersion)',
              name: 'UpdateService');

          return UpdateInfo(
            version: latestVersion,
            currentVersion: currentVersion,
            releaseUrl: releaseUrl,
            releaseNotes: releaseNotes,
          );
        } else {
          log('App is up to date: $currentVersion', name: 'UpdateService');
        }
      } else {
        log('Failed to check for updates: ${response.statusCode}',
            name: 'UpdateService');
      }
    } catch (e) {
      log('Error checking for updates: $e', name: 'UpdateService');
    }

    return null;
  }

  /// Compare version strings (e.g., "2.11.6" vs "2.11.7")
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latestParts = latestVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Ensure both have same number of parts
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }

      // Compare each part
      for (int i = 0; i < latestParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      log('Error comparing versions: $e', name: 'UpdateService');
      return false;
    }
  }
}

/// Information about an available update
class UpdateInfo {
  final String version;
  final String currentVersion;
  final String releaseUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.currentVersion,
    required this.releaseUrl,
    required this.releaseNotes,
  });
}
