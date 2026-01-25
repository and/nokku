# Safe Gallery - Developer Setup Guide

This guide will help you set up the Safe Gallery project for development.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`

2. **For Android Development**:
   - Android Studio (latest version)
   - Android SDK (API level 21+)
   - Java Development Kit (JDK 11 or higher)

3. **For iOS Development** (macOS only):
   - Xcode 14 or higher
   - CocoaPods: `sudo gem install cocoapods`
   - iOS Simulator or physical device

4. **Git**: `git --version`

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd safe_gallery
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

This will download all required packages defined in `pubspec.yaml`.

### 3. Verify Flutter Installation

```bash
flutter doctor
```

Resolve any issues reported by Flutter Doctor before proceeding.

## Platform-Specific Setup

### Android Setup

#### 1. Configure Android SDK

Make sure Android SDK is properly configured:

```bash
flutter doctor --android-licenses
```

Accept all licenses.

#### 2. Create/Update local.properties

In `android/local.properties`, add your SDK path:

```properties
sdk.dir=/path/to/Android/sdk
flutter.sdk=/path/to/flutter
```

#### 3. Build and Run

```bash
# Connect Android device or start emulator
flutter devices

# Run on connected device
flutter run
```

#### 4. Test Device Admin

1. Install the app
2. Open app → Settings → Security
3. Tap "Device Admin"
4. Grant permission
5. Test presentation mode lock behavior

### iOS Setup

#### 1. Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

#### 2. Open Xcode Project

```bash
open ios/Runner.xcworkspace
```

#### 3. Configure Signing

In Xcode:
1. Select "Runner" project
2. Select "Runner" target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Xcode will automatically create a provisioning profile

#### 4. Build and Run

```bash
# List available iOS devices
flutter devices

# Run on connected device/simulator
flutter run -d ios
```

#### 5. Test Guided Access (Physical Device)

1. Go to iOS Settings → Accessibility → Guided Access
2. Toggle ON
3. Set passcode
4. Open Safe Gallery
5. Enter presentation mode
6. Triple-click home/side button to start Guided Access
7. Triple-click again to exit

## Project Structure Overview

```
safe_gallery/
├── lib/
│   ├── models/          # Data models (Collection, PhotoItem, AppSettings)
│   ├── services/        # Business logic (Database, Photo, Lock, Settings)
│   ├── providers/       # State management (AppProvider)
│   ├── screens/         # UI screens
│   └── main.dart        # App entry point
├── android/
│   ├── app/src/main/
│   │   ├── kotlin/      # Android native code
│   │   ├── res/         # Android resources
│   │   └── AndroidManifest.xml
│   └── build.gradle
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift  # iOS native code
│   │   └── Info.plist
│   └── Podfile
├── pubspec.yaml         # Flutter dependencies
└── README.md
```

## Key Dependencies

From `pubspec.yaml`:

- **provider**: State management
- **sqflite**: Local database
- **photo_manager**: Photo library access
- **shared_preferences**: Settings storage
- **receive_sharing_intent**: Share sheet integration
- **cached_network_image**: Image caching
- **uuid**: Unique ID generation

## Development Workflow

### 1. Running in Debug Mode

```bash
# Hot reload enabled
flutter run
```

Press `r` to hot reload, `R` to hot restart.

### 2. Running Tests

```bash
flutter test
```

### 3. Code Analysis

```bash
flutter analyze
```

### 4. Format Code

```bash
flutter format lib/
```

### 5. Clean Build

If you encounter build issues:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Building for Release

### Android Release Build

#### APK (Direct install):

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (Google Play):

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS Release Build

```bash
flutter build ios --release
```

Then in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Product → Archive
3. Distribute App

## Debugging Tips

### Android

**View Logs**:
```bash
flutter logs
# or
adb logcat
```

**Debug Native Code**:
1. Open `android/` in Android Studio
2. Set breakpoints in Kotlin files
3. Run → Debug 'app'

### iOS

**View Logs**:
```bash
flutter logs
```

**Debug Native Code**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set breakpoints in Swift files
3. Run (⌘R)

## Common Issues & Solutions

### Issue: "Flutter SDK not found"

**Solution**:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

Add to `.bashrc` or `.zshrc` for persistence.

### Issue: Android build fails with Gradle error

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: iOS build fails with CocoaPods error

**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

### Issue: Photos not loading

**Solution**:
- Ensure photo permissions are granted
- Check device settings → App → Permissions → Photos

### Issue: Device Admin not working (Android)

**Solution**:
- Manually enable in device Settings → Security → Device Admin
- Some manufacturers block this (Xiaomi, Huawei) - check MIUI/EMUI settings

## Platform Channel Communication

### Android (Kotlin → Dart)

`android/app/src/main/kotlin/com/safegallery/MainActivity.kt`:

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "lockDevice" -> {
                // Native implementation
                result.success(true)
            }
        }
    }
```

### iOS (Swift → Dart)

`ios/Runner/AppDelegate.swift`:

```swift
let lockChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
lockChannel.setMethodCallHandler { (call, result) in
    switch call.method {
    case "lockDevice":
        // Native implementation
        result(false)
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

### Dart (Calling Native)

`lib/services/lock_service.dart`:

```dart
static const MethodChannel _channel = MethodChannel('com.safegallery/lock');

Future<void> lockDevice() async {
    await _channel.invokeMethod('lockDevice');
}
```

## Testing Checklist

Before committing:

- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes all tests
- [ ] App builds successfully on Android
- [ ] App builds successfully on iOS
- [ ] Device locking works on Android (with Device Admin)
- [ ] Presentation mode works smoothly
- [ ] Photo picker works
- [ ] Share sheet integration works
- [ ] Settings persist correctly
- [ ] Collections CRUD operations work
- [ ] UI matches platform guidelines

## Getting Help

- Flutter Docs: https://flutter.dev/docs
- Flutter Community: https://flutter.dev/community
- Package Issues: Check individual package GitHub repos

## Next Steps

1. Run the app: `flutter run`
2. Create a test collection
3. Test presentation mode
4. Enable device admin (Android) or Guided Access (iOS)
5. Test device locking behavior

Happy coding! 🚀
