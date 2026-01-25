import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IntentService {
  static const MethodChannel _channel = MethodChannel('com.safegallery/intent');

  /// Get shared files from Android intent
  static Future<List<String>> getSharedFiles() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSharedFiles');
      return result.cast<String>();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error getting shared files: ${e.message}');
      }
      return [];
    }
  }

  /// Check if app was launched with shared content
  static Future<bool> hasSharedContent() async {
    try {
      final bool result = await _channel.invokeMethod('hasSharedContent');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error checking shared content: ${e.message}');
      }
      return false;
    }
  }

  /// Clear shared content after processing
  static Future<void> clearSharedContent() async {
    try {
      await _channel.invokeMethod('clearSharedContent');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error clearing shared content: ${e.message}');
      }
    }
  }

  /// Request storage permission
  static Future<void> requestStoragePermission() async {
    try {
      await _channel.invokeMethod('requestStoragePermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error requesting storage permission: ${e.message}');
      }
    }
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasStoragePermission');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error checking storage permission: ${e.message}');
      }
      return false;
    }
  }
}