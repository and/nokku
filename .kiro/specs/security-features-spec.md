# Safe Gallery - Security Features Specification

## Overview

Safe Gallery implements comprehensive security features to prevent unauthorized access during photo presentations. The security model varies by platform due to iOS and Android architectural differences, but both provide effective protection mechanisms.

## Security Architecture

### Core Security Principles
- **Device-Level Protection**: Lock device rather than just app
- **Platform-Native Integration**: Use OS-provided security APIs
- **User Control**: Users maintain ultimate control over security settings
- **Transparent Operation**: Clear communication about security features
- **Graceful Degradation**: Functional without security features enabled

### Security Layers
```
Application Layer (Flutter)
    ↓
Platform Channel Layer
    ↓
Native Security APIs (Android/iOS)
    ↓
Operating System Security
```

## Android Security Implementation

### Device Admin Integration

#### Device Admin Receiver
**File**: `android/app/src/main/kotlin/com/safegallery/DeviceAdminReceiver.kt`

```kotlin
class DeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin permission granted
        // App can now lock device programmatically
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device admin permission revoked
        // Locking functionality disabled
    }
}
```

#### Device Admin Policy
**File**: `android/app/src/main/res/xml/device_admin.xml`

```xml
<device-admin xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-policies>
        <force-lock />  <!-- Only permission requested -->
    </uses-policies>
</device-admin>
```

**Minimal Permissions**: Only requests device locking capability, no other admin functions.

#### Device Locking Implementation
```kotlin
private fun lockDevice(): Boolean {
    return if (devicePolicyManager.isAdminActive(componentName)) {
        devicePolicyManager.lockNow()  // Immediate device lock
        true  // Success
    } else {
        // Fallback: Request keyguard (limited effectiveness)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }
        false  // Device admin required for true locking
    }
}
```

### Immersive Mode Protection

#### Full-Screen Presentation
```kotlin
private fun enterPresentationMode() {
    activity?.runOnUiThread {
        // Modern Android (API 30+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(
                    WindowInsets.Type.statusBars() or 
                    WindowInsets.Type.navigationBars()
                )
                controller.systemBarsBehavior = 
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Legacy Android (API 21-29)
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
            )
        }
        
        // Prevent screen from sleeping
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
```

#### System UI Behavior
- **Immersive Sticky Mode**: System UI hidden but can be revealed with swipe
- **Transient Bars**: Status/navigation bars auto-hide after brief display
- **Screen Wake Lock**: Prevents screen from turning off during presentation

### Permission Management

#### Device Admin Permission Request
```kotlin
private fun requestDeviceAdmin() {
    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
    intent.putExtra(
        DevicePolicyManager.EXTRA_ADD_EXPLANATION,
        "Safe Gallery needs device admin permission to lock your device when exiting presentation mode."
    )
    startActivityForResult(intent, 1)
}
```

#### Permission Status Check
```kotlin
fun isDeviceAdminEnabled(): Boolean {
    return devicePolicyManager.isAdminActive(componentName)
}
```

## iOS Security Implementation

### Guided Access Integration

#### iOS Security Limitations
- **No Programmatic Locking**: iOS security model prevents apps from locking device
- **User-Controlled Security**: Users must manually enable Guided Access
- **System-Level Protection**: Guided Access provides true kiosk mode

#### Presentation Mode Setup
```swift
private func enterPresentationMode() {
    DispatchQueue.main.async {
        // Hide status bar by elevating window level
        if let window = UIApplication.shared.windows.first {
            window.windowLevel = .statusBar + 1
        }
        
        // Prevent screen from sleeping
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
```

#### Guided Access Instructions
**In-App Guidance**:
```swift
private func showGuidedAccessInstructions() {
    let alert = UIAlertController(
        title: "Enable Guided Access",
        message: """
        1. Go to Settings > Accessibility > Guided Access
        2. Turn on Guided Access
        3. Set a passcode
        4. When viewing photos:
           - Triple-click home/side button to start
           - Triple-click again to exit
        """,
        preferredStyle: .alert
    )
    // ... present alert
}
```

### iOS Security Features

#### App Lifecycle Monitoring
```dart
class _PresentationScreenState extends State<PresentationScreen> 
    with WidgetsBindingObserver {
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Detect when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // On iOS, this is the best we can do
      // User should have Guided Access enabled
      if (!_isExiting) {
        _showSecurityWarning();
      }
    }
  }
}
```

## Cross-Platform Security Features

### Presentation Mode Management

#### Flutter Security Service
**File**: `lib/services/lock_service.dart`

```dart
class LockService {
  static const MethodChannel _channel = MethodChannel('com.safegallery/lock');
  
  bool _isPresentationMode = false;
  Timer? _autoLockTimer;

  // Enter secure presentation mode
  Future<void> enterPresentationMode() async {
    _isPresentationMode = true;
    try {
      await _channel.invokeMethod('enterPresentationMode');
    } on PlatformException catch (e) {
      print('Failed to enter presentation mode: ${e.message}');
    }
  }

  // Lock device immediately
  Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod('lockDevice');
    } on PlatformException catch (e) {
      print('Failed to lock device: ${e.message}');
    }
  }
}
```

### Auto-Lock Timer

#### Timer Implementation
```dart
void startAutoLockTimer(int minutes) {
  _cancelAutoLockTimer();
  _autoLockTimer = Timer(Duration(minutes: minutes), () {
    lockDevice();  // Automatic device lock
  });
}

void resetAutoLockTimer(int minutes) {
  if (_autoLockTimer != null) {
    startAutoLockTimer(minutes);  // Reset on user interaction
  }
}
```

#### User Interaction Detection
```dart
// In PresentationScreen
GestureDetector(
  onTap: () => _resetAutoLockTimer(),
  onHorizontalDragEnd: (details) => _resetAutoLockTimer(),
  child: PageView(...),
)
```

### Navigation Protection

#### Back Button Override
```dart
PopScope(
  canPop: false,  // Prevent back navigation
  onPopInvoked: (didPop) {
    if (!didPop) {
      // Lock device instead of allowing navigation
      _lockDevice();
    }
  },
  child: PresentationContent(),
)
```

#### App Lifecycle Protection
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  // Critical: Lock device when app goes to background
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    if (!_isExiting) {
      _lockDevice();  // Immediate security response
    }
  }
}
```

## Security Settings Management

### User Configuration
```dart
class AppSettings {
  final bool autoLockEnabled;      // Enable auto-lock timer
  final int autoLockMinutes;       // Minutes until auto-lock (1-15)
  
  // Security-related presentation settings
  final bool pinchToZoom;          // May affect security (disable for kiosk)
  final bool showPhotoCounter;     // Information disclosure consideration
}
```

### Settings UI Integration
```dart
// Android Settings
SwitchListTile(
  title: Text('Auto-lock Timer'),
  subtitle: Text(settings.autoLockEnabled 
    ? 'Lock after ${settings.autoLockMinutes} min'
    : 'Disabled'),
  value: settings.autoLockEnabled,
  onChanged: (value) => updateSettings(settings.copyWith(autoLockEnabled: value)),
)

// Device Admin Status
FutureBuilder<bool>(
  future: LockService().isDeviceAdminEnabled(),
  builder: (context, snapshot) {
    final isEnabled = snapshot.data ?? false;
    return ListTile(
      title: Text('Device Admin'),
      subtitle: Text(isEnabled 
        ? 'Enabled - allows locking device on exit'
        : 'Not enabled - tap to enable device locking'),
      trailing: isEnabled 
        ? Icon(Icons.check_circle, color: Colors.green)
        : Icon(Icons.warning, color: Colors.orange),
      onTap: isEnabled ? null : () => LockService().requestDeviceAdmin(),
    );
  },
)
```

## Security Threat Model

### Threats Addressed

#### Unauthorized Access During Presentation
- **Threat**: User tries to exit app to access other content
- **Mitigation**: Device locking on exit attempts
- **Platforms**: Android (device admin), iOS (Guided Access)

#### Accidental Exit
- **Threat**: Unintentional navigation away from presentation
- **Mitigation**: Back button override, gesture interception
- **Platforms**: Both Android and iOS

#### Extended Unattended Access
- **Threat**: Device left unattended during presentation
- **Mitigation**: Auto-lock timer with configurable duration
- **Platforms**: Both Android and iOS

#### System UI Access
- **Threat**: Access to notifications, control center, etc.
- **Mitigation**: Immersive mode (Android), elevated window (iOS)
- **Platforms**: Platform-specific implementations

### Threats Not Addressed

#### Screenshot/Screen Recording
- **Rationale**: Owner controls device, should be able to capture content
- **Alternative**: Could be added as optional feature

#### Physical Device Access
- **Rationale**: Physical security is user's responsibility
- **Note**: Device locking provides standard OS-level protection

#### Network-Based Attacks
- **Rationale**: App operates entirely offline
- **Note**: No network communication during presentation

## Security Best Practices

### Principle of Least Privilege
- **Android**: Only requests device admin permission, no other admin rights
- **iOS**: Uses standard app permissions, recommends user-controlled Guided Access
- **Data Access**: Read-only photo library access

### User Transparency
- **Clear Permissions**: Explicit explanation of why device admin is needed
- **User Control**: All security features can be disabled by user
- **Visual Indicators**: Clear UI showing security status

### Graceful Degradation
- **Without Device Admin**: App still functions, shows warnings
- **Without Guided Access**: App provides instructions, works with limitations
- **Fallback Behaviors**: Alternative security measures when primary methods unavailable

### Security Testing

#### Android Testing
```bash
# Test device admin functionality
adb shell dpm set-device-admin com.safegallery/.DeviceAdminReceiver

# Test device locking
adb shell input keyevent KEYCODE_POWER  # Should lock immediately

# Test immersive mode
adb shell settings put global policy_control immersive.full=com.safegallery
```

#### iOS Testing
```bash
# Test Guided Access (manual)
# 1. Enable Guided Access in Settings
# 2. Triple-click home button in app
# 3. Verify app restriction
# 4. Triple-click to exit with passcode
```

## Security Compliance

### Privacy Compliance
- **No Data Collection**: Zero analytics or tracking
- **Local Storage Only**: All data remains on device
- **Transparent Permissions**: Clear explanation of required access

### Platform Compliance
- **Android**: Follows device admin best practices
- **iOS**: Uses recommended security patterns
- **App Store Guidelines**: Compliant with both Google Play and App Store policies

This security specification ensures robust protection during photo presentations while maintaining user control and platform compliance.