import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check if an update is available and show update prompt if needed
  /// Returns true if update check was performed, false if skipped (iOS or error)
  Future<bool> checkForUpdate() async {
    // In-app updates only work on Android
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print('Update check skipped: iOS does not support in-app updates');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('Checking for app updates...');
      }

      // Check if update is available
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (kDebugMode) {
        print('Update available: ${updateInfo.updateAvailability}');
        print('Immediate update allowed: ${updateInfo.immediateUpdateAllowed}');
        print('Flexible update allowed: ${updateInfo.flexibleUpdateAllowed}');
      }

      // If update is available, show flexible update prompt
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.flexibleUpdateAllowed) {
          await _performFlexibleUpdate();
          return true;
        } else if (updateInfo.immediateUpdateAllowed) {
          // Fallback to immediate update if flexible is not allowed
          await _performImmediateUpdate();
          return true;
        }
      }

      if (kDebugMode) {
        print('No update available or update not allowed');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates: $e');
      }
      return false;
    }
  }

  /// Perform flexible update - user can continue using app while downloading
  Future<void> _performFlexibleUpdate() async {
    try {
      if (kDebugMode) {
        print('Starting flexible update...');
      }

      await InAppUpdate.startFlexibleUpdate();

      if (kDebugMode) {
        print('Flexible update download started');
      }

      // Complete the update when download is finished
      await InAppUpdate.completeFlexibleUpdate();

      if (kDebugMode) {
        print('Flexible update completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error performing flexible update: $e');
      }
    }
  }

  /// Perform immediate update - blocks app until update is installed
  /// Use this for critical updates only
  Future<void> _performImmediateUpdate() async {
    try {
      if (kDebugMode) {
        print('Starting immediate update...');
      }

      await InAppUpdate.performImmediateUpdate();

      if (kDebugMode) {
        print('Immediate update completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error performing immediate update: $e');
      }
    }
  }

  /// Check for update with custom priority
  /// Priority can be used to determine if update should be immediate or flexible
  /// Priority 5 (highest) = immediate update required
  /// Priority 1-4 = flexible update
  Future<void> checkForUpdateWithPriority() async {
    if (!Platform.isAndroid) return;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // You can implement priority-based update logic here
        // For now, we default to flexible updates
        if (updateInfo.flexibleUpdateAllowed) {
          await _performFlexibleUpdate();
        } else if (updateInfo.immediateUpdateAllowed) {
          await _performImmediateUpdate();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates with priority: $e');
      }
    }
  }
}
