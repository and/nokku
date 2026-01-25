# Safe Gallery - Platform Integration Specification

## Overview

Safe Gallery integrates deeply with Android and iOS platforms to provide secure photo presentation with device locking capabilities. This spec details the platform-specific implementations and native code integration.

## Platform Channel Architecture

### Channel Definition
```dart
// Dart side
static const MethodChannel _channel = MethodChannel('com.safegallery/lock');
```

### Method Call Interface
```dart
// Available methods
await _channel.invokeMethod('enterPresentationMode');
await _channel.invokeMethod('exitPresentationMode');
await _channel.invokeMethod('lockDevice');
await _channel.invokeMethod('isDeviceAdminEnabled');  // Android only
await _channel.invokeMethod('requestDeviceAdmin');    // Android only
```

## Android Platform Integration

### Native Implementation
**File**: `android/app/src/main/kotlin/com/safegallery/MainActivity.kt`

#### Core Components

**Device Policy Manager Setup**:
```kotlin
private lateinit var devicePolicyManager: DevicePolicyManager
private lateinit var componentName: ComponentName

override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    componentName = ComponentName(this, DeviceAdminReceiver::class.java)
}
```

**Method Channel Handler**:
```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "enterPresentationMode" -> {
                enterPresentationMode()
                result.success(null)
            }
            "lockDevice" -> {
                val locked = lockDevice()
                result.success(locked)
            }
            // ... other methods
        }
    }
```

#### Presentation Mode Implementation

**Immersive Mode (Android 11+)**:
```kotlin
private fun enterPresentationMode() {
    activity?.runOnUiThread {
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
        }
        // Keep screen on during presentation
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
```

**Legacy Immersive Mode (Android 5-10)**:
```kotlin
@Suppress("DEPRECATION")
window.decorView.systemUiVisibility = (
    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
    or View.SYSTEM_UI_FLAG_FULLSCREEN
)
```

#### Device Locking Implementation

**Primary Method (Device Admin)**:
```kotlin
private fun lockDevice(): Boolean {
    return if (devicePolicyManager.isAdminActive(componentName)) {
        devicePolicyManager.lockNow()  // Immediate device lock
        true
    } else {
        // Fallback for devices without device admin
        false
    }
}
```

**Device Admin Permission Request**:
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

### Device Admin Receiver
**File**: `android/app/src/main/kotlin/com/safegallery/DeviceAdminReceiver.kt`

```kotlin
class DeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin enabled - app can now lock device
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device admin disabled - locking no longer available
    }
}
```

### Android Manifest Configuration
**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Device Admin Receiver -->
<receiver android:name=".DeviceAdminReceiver"
          android:permission="android.permission.BIND_DEVICE_ADMIN">
    <meta-data android:name="android.app.device_admin"
               android:resource="@xml/device_admin" />
    <intent-filter>
        <action android:name="android.app.action.DEVICE_ADMIN_ENABLED" />
    </intent-filter>
</receiver>

<!-- Required permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Device Admin Policy
**File**: `android/app/src/main/res/xml/device_admin.xml`

```xml
<device-admin xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-policies>
        <force-lock />
    </uses-policies>
</device-admin>
```

## iOS Platform Integration

### Native Implementation
**File**: `ios/Runner/AppDelegate.swift`

#### Method Channel Handler
```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let lockChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    lockChannel.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "enterPresentationMode":
            self?.enterPresentationMode()
            result(nil)
        case "lockDevice":
            // iOS cannot programmatically lock device
            result(false)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

#### Presentation Mode Implementation
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

private func exitPresentationMode() {
    DispatchQueue.main.async {
        // Restore normal window level
        if let window = UIApplication.shared.windows.first {
            window.windowLevel = .normal
        }
        
        // Allow screen to sleep normally
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
```

#### iOS Security Limitations
- **No Programmatic Locking**: iOS security model prevents apps from locking the device
- **Guided Access Recommendation**: Users must manually enable Guided Access
- **App Backgrounding**: When app backgrounds, Flutter detects and can show appropriate UI

### iOS Info.plist Configuration
**File**: `ios/Runner/Info.plist`

```xml
<!-- Photo library access -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Safe Gallery needs access to your photos to create collections for secure presentation.</string>

<!-- Prevent app backgrounding during presentation -->
<key>UIApplicationExitsOnSuspend</key>
<false/>
```

## Share Sheet Integration

### Android Share Intent
**Manifest Configuration**:
```xml
<activity android:name=".MainActivity"
          android:exported="true">
    <!-- Share intent filter -->
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <action android:name="android.intent.action.SEND_MULTIPLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
    </intent-filter>
</activity>
```

### iOS Share Extension
**Info.plist Configuration**:
```xml
<!-- URL schemes for share sheet -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>safegallery.share</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>safegallery</string>
        </array>
    </dict>
</array>
```

### Flutter Share Intent Handling
```dart
// Initialize sharing intent listener
void _initSharing() {
    // Handle shared files when app opens from share sheet
    ReceiveSharingIntent.getInitialMedia().then((files) {
        if (files.isNotEmpty) {
            _handleSharedFiles(files);
        }
    });

    // Handle shared files while app is running
    ReceiveSharingIntent.getMediaStream().listen((files) {
        if (files.isNotEmpty) {
            _handleSharedFiles(files);
        }
    });
}
```

## Photo Library Integration

### Cross-Platform Photo Access
```dart
// Permission request
final PermissionState ps = await PhotoManager.requestPermissionExtend();
final hasAccess = ps.isAuth || ps.hasAccess;

// Album enumeration
final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
    ),
);

// Photo loading with pagination
final List<AssetEntity> photos = await album.getAssetListPaged(
    page: page,
    size: size,
);
```

### Thumbnail Generation
```dart
// Generate 200x200 thumbnails
final File? thumbFile = await asset.thumbDataWithSize(200, 200).then((data) async {
    if (data == null) return null;
    final tempDir = Directory.systemTemp;
    final thumbPath = '${tempDir.path}/thumb_${asset.id}.jpg';
    final thumbFile = File(thumbPath);
    await thumbFile.writeAsBytes(data);
    return thumbFile;
});
```

## Platform-Specific Behaviors

### Android Advantages
- **True Device Locking**: DevicePolicyManager.lockNow() provides immediate device lock
- **Immersive Mode**: Full system UI hiding with gesture override
- **Device Admin Integration**: Robust permission system for security features
- **Share Intent**: Native Android sharing integration

### Android Limitations
- **Device Admin Permission**: Requires manual user activation
- **Manufacturer Variations**: Some OEMs (Xiaomi, Huawei) may restrict device admin
- **Battery Optimization**: May interfere with background operations

### iOS Advantages
- **Guided Access Integration**: Provides true kiosk mode when enabled
- **Smooth Animations**: Native iOS transitions and gestures
- **Privacy Controls**: Granular photo library access permissions
- **Share Sheet**: Native iOS sharing integration

### iOS Limitations
- **No Programmatic Locking**: Cannot lock device from app code
- **Manual Setup Required**: User must enable Guided Access manually
- **Limited System UI Control**: Cannot fully hide system indicators

## Security Considerations

### Android Security Model
- Device Admin permission provides legitimate device management
- User explicitly grants permission through system settings
- Can be revoked at any time by user
- Follows Android security best practices

### iOS Security Model
- Guided Access provides supervised app restriction
- User maintains full control through triple-click gesture
- No app-level device control (by design)
- Relies on iOS built-in security features

### Privacy Protection
- **Local Storage Only**: No cloud sync or external data transmission
- **Read-Only Photo Access**: Cannot modify or delete user photos
- **No Analytics**: Zero tracking or data collection
- **Transparent Permissions**: Clear explanation of required permissions

## Testing Platform Integration

### Android Testing
```bash
# Test device admin functionality
adb shell dpm set-device-admin com.safegallery/.DeviceAdminReceiver

# Test immersive mode
adb shell settings put global policy_control immersive.full=com.safegallery

# Test share intent
adb shell am start -a android.intent.action.SEND -t "image/*" --eu android.intent.extra.STREAM file:///path/to/image.jpg
```

### iOS Testing
```bash
# Test photo library access
xcrun simctl privacy booted grant photos com.safegallery

# Test share sheet integration
# (Manual testing required through iOS Simulator)
```

This platform integration specification ensures robust, secure functionality across both Android and iOS while respecting each platform's security model and user experience conventions.