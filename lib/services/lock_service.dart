import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LockService {
  static final LockService _instance = LockService._internal();
  factory LockService() => _instance;
  LockService._internal();

  static const MethodChannel _channel = MethodChannel('com.safegallery/lock');

  bool _isPresentationMode = false;
  Timer? _autoLockTimer;

  bool get isPresentationMode => _isPresentationMode;

  // Initialize presentation mode with device locking
  Future<void> enterPresentationMode() async {
    _isPresentationMode = true;
    try {
      await _channel.invokeMethod('enterPresentationMode');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to enter presentation mode: ${e.message}');
      }
    }
  }

  // Exit presentation mode
  Future<void> exitPresentationMode() async {
    _isPresentationMode = false;
    _cancelAutoLockTimer();
    try {
      await _channel.invokeMethod('exitPresentationMode');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to exit presentation mode: ${e.message}');
      }
    }
  }

  // Lock device immediately
  Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod('lockDevice');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to lock device: ${e.message}');
      }
    }
  }

  // Start auto-lock timer
  void startAutoLockTimer(int minutes) {
    _cancelAutoLockTimer();
    _autoLockTimer = Timer(Duration(minutes: minutes), () {
      lockDevice();
    });
  }

  // Cancel auto-lock timer
  void _cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  // Reset auto-lock timer (call on user interaction)
  void resetAutoLockTimer(int minutes) {
    if (_autoLockTimer != null) {
      startAutoLockTimer(minutes);
    }
  }

  // Check if device admin is enabled (Android only)
  Future<bool> isDeviceAdminEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isDeviceAdminEnabled');
      return result;
    } on PlatformException {
      return false;
    }
  }

  // Request device admin permission (Android only)
  Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to request device admin: ${e.message}');
      }
    }
  }
}
