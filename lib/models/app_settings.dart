enum AppThemeMode { system, light, dark }

class AppSettings {
  // Presentation settings
  final bool pinchToZoom;
  final bool showPhotoCounter;
  final bool autoAdvance;
  final int autoAdvanceInterval; // in seconds
  final bool autoLockEnabled;
  final int autoLockMinutes;
  final bool confirmPhotoRemoval; // Confirmation dialog for photo removal
  final bool swipeToDelete; // Enable/disable swipe up to delete feature

  // Display settings
  final AppThemeMode themeMode;
  final bool transitionAnimations;

  AppSettings({
    this.pinchToZoom = false,
    this.showPhotoCounter = false,
    this.autoAdvance = false,
    this.autoAdvanceInterval = 5,
    this.autoLockEnabled = false,
    this.autoLockMinutes = 5,
    this.confirmPhotoRemoval = false, // Default to false (no confirmation)
    this.swipeToDelete = true, // Default to true (feature enabled)
    this.themeMode = AppThemeMode.system,
    this.transitionAnimations = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'pinchToZoom': pinchToZoom,
      'showPhotoCounter': showPhotoCounter,
      'autoAdvance': autoAdvance,
      'autoAdvanceInterval': autoAdvanceInterval,
      'autoLockEnabled': autoLockEnabled,
      'autoLockMinutes': autoLockMinutes,
      'confirmPhotoRemoval': confirmPhotoRemoval,
      'swipeToDelete': swipeToDelete,
      'themeMode': themeMode.toString(),
      'transitionAnimations': transitionAnimations,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      pinchToZoom: map['pinchToZoom'] as bool? ?? false,
      showPhotoCounter: map['showPhotoCounter'] as bool? ?? false,
      autoAdvance: map['autoAdvance'] as bool? ?? false,
      autoAdvanceInterval: map['autoAdvanceInterval'] as int? ?? 5,
      autoLockEnabled: map['autoLockEnabled'] as bool? ?? false,
      autoLockMinutes: map['autoLockMinutes'] as int? ?? 5,
      confirmPhotoRemoval: map['confirmPhotoRemoval'] as bool? ?? false,
      swipeToDelete: map['swipeToDelete'] as bool? ?? true,
      themeMode: _parseThemeMode(map['themeMode'] as String?),
      transitionAnimations: map['transitionAnimations'] as bool? ?? true,
    );
  }

  static AppThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'AppThemeMode.light':
        return AppThemeMode.light;
      case 'AppThemeMode.dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  AppSettings copyWith({
    bool? pinchToZoom,
    bool? showPhotoCounter,
    bool? autoAdvance,
    int? autoAdvanceInterval,
    bool? autoLockEnabled,
    int? autoLockMinutes,
    bool? confirmPhotoRemoval,
    bool? swipeToDelete,
    AppThemeMode? themeMode,
    bool? transitionAnimations,
  }) {
    return AppSettings(
      pinchToZoom: pinchToZoom ?? this.pinchToZoom,
      showPhotoCounter: showPhotoCounter ?? this.showPhotoCounter,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      autoAdvanceInterval: autoAdvanceInterval ?? this.autoAdvanceInterval,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      confirmPhotoRemoval: confirmPhotoRemoval ?? this.confirmPhotoRemoval,
      swipeToDelete: swipeToDelete ?? this.swipeToDelete,
      themeMode: themeMode ?? this.themeMode,
      transitionAnimations: transitionAnimations ?? this.transitionAnimations,
    );
  }
}
