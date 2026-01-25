# Safe Gallery - Deployment & Build Specification

## Overview

Safe Gallery supports deployment to both Android and iOS platforms with optimized build configurations for development, testing, and production environments. This spec covers build processes, release preparation, and deployment strategies.

## Build Architecture

### Build Environments
```
Development → Testing → Staging → Production
     ↓           ↓         ↓          ↓
   Debug     Profile   Release    Release
   Build     Build     Build      Build
```

### Platform Targets
- **Android**: APK (direct install) and AAB (Google Play)
- **iOS**: IPA (App Store) and development builds
- **Minimum Versions**: Android 5.0 (API 21), iOS 12.0

## Development Build Configuration

### Flutter Development Setup
```bash
# Verify Flutter installation
flutter doctor

# Install dependencies
flutter pub get

# Run in development mode (hot reload enabled)
flutter run --debug

# Run with specific device
flutter run -d android
flutter run -d ios
```

### Development Build Features
- **Hot Reload**: Instant code changes
- **Debug Symbols**: Full debugging information
- **Assertions**: Runtime checks enabled
- **Observatory**: Performance profiling tools
- **Larger Binary Size**: Debug information included

## Android Build Configuration

### Gradle Configuration
**File**: `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.safegallery"
        minSdkVersion 21  // Android 5.0
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        debug {
            debuggable true
            minifyEnabled false
            shrinkResources false
        }
        
        profile {
            debuggable false
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        
        release {
            debuggable false
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}
```

### ProGuard Configuration
**File**: `android/app/proguard-rules.pro`

```proguard
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Safe Gallery specific rules
-keep class com.safegallery.** { *; }

# Photo manager plugin
-keep class com.fluttercandies.photo_manager.** { *; }

# SQLite
-keep class io.flutter.plugins.sqflite.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
```

### Android Signing Configuration
**File**: `android/key.properties` (not in version control)

```properties
storePassword=<store_password>
keyPassword=<key_password>
keyAlias=<key_alias>
storeFile=<path_to_keystore>
```

**File**: `android/app/build.gradle` (signing config)

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

### Android Build Commands

#### Debug Build
```bash
# APK for testing
flutter build apk --debug

# Install on connected device
flutter install --debug
```

#### Profile Build
```bash
# Optimized build with some debugging
flutter build apk --profile

# Performance testing
flutter run --profile
```

#### Release Build
```bash
# APK for direct distribution
flutter build apk --release

# App Bundle for Google Play Store
flutter build appbundle --release

# Split APKs by architecture
flutter build apk --release --split-per-abi
```

### Android Build Outputs
```
build/app/outputs/
├── flutter-apk/
│   ├── app-release.apk           # Universal APK
│   ├── app-arm64-v8a-release.apk # ARM64 APK
│   └── app-armeabi-v7a-release.apk # ARM32 APK
└── bundle/release/
    └── app-release.aab           # App Bundle for Play Store
```

## iOS Build Configuration

### Xcode Project Configuration
**File**: `ios/Runner.xcodeproj/project.pbxproj`

Key settings:
- **Deployment Target**: iOS 12.0
- **Swift Version**: 5.0
- **Bitcode**: Enabled for App Store
- **App Transport Security**: Configured for photo access

### iOS Info.plist Configuration
**File**: `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Safe Gallery</string>
    
    <key>CFBundleIdentifier</key>
    <string>com.safegallery</string>
    
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <!-- Photo Library Access -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Safe Gallery needs access to your photos to create collections for secure presentation.</string>
    
    <!-- Prevent app backgrounding during presentation -->
    <key>UIApplicationExitsOnSuspend</key>
    <false/>
    
    <!-- Supported orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
</dict>
</plist>
```

### iOS Build Commands

#### Debug Build
```bash
# Build for iOS simulator
flutter build ios --debug --simulator

# Build for device
flutter build ios --debug

# Run on device/simulator
flutter run -d ios
```

#### Profile Build
```bash
# Profile build for performance testing
flutter build ios --profile

# Run with profiling
flutter run --profile -d ios
```

#### Release Build
```bash
# Release build for App Store
flutter build ios --release

# Build with specific configuration
flutter build ios --release --flavor production
```

### iOS Signing & Provisioning

#### Development Signing
```bash
# Automatic signing (recommended for development)
# Configured in Xcode: Runner → Signing & Capabilities
# - Team: Select development team
# - Provisioning Profile: Automatic
```

#### Distribution Signing
```bash
# App Store distribution
# Configured in Xcode: Runner → Signing & Capabilities
# - Team: Select distribution team
# - Provisioning Profile: App Store distribution profile
```

### iOS Archive & Distribution

#### Create Archive
```bash
# Open Xcode workspace
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device" as target
# 2. Product → Archive
# 3. Wait for archive to complete
```

#### Distribute to App Store
```bash
# In Xcode Organizer:
# 1. Select archive
# 2. Click "Distribute App"
# 3. Choose "App Store Connect"
# 4. Follow upload wizard
```

## Version Management

### Version Configuration
**File**: `pubspec.yaml`

```yaml
name: safe_gallery
description: A temporary photo presentation app with secure viewing mode
version: 1.0.0+1  # version+build_number

environment:
  sdk: '>=3.0.0 <4.0.0'
```

### Version Bump Strategy
```bash
# Patch version (1.0.0 → 1.0.1)
# For bug fixes
flutter pub version patch

# Minor version (1.0.0 → 1.1.0)
# For new features
flutter pub version minor

# Major version (1.0.0 → 2.0.0)
# For breaking changes
flutter pub version major

# Custom version
flutter pub version 1.2.3+4
```

### Build Number Management
```bash
# Increment build number only
flutter build apk --build-number=5

# Set specific version and build
flutter build apk --build-name=1.1.0 --build-number=6
```

## Release Preparation

### Pre-Release Checklist

#### Code Quality
- [ ] All tests passing (`flutter test`)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] Performance profiling completed
- [ ] Security review completed
- [ ] Documentation updated

#### Platform Testing
- [ ] Android: Tested on multiple devices/API levels
- [ ] iOS: Tested on multiple devices/iOS versions
- [ ] Device admin functionality verified (Android)
- [ ] Guided Access instructions verified (iOS)
- [ ] Share sheet integration tested

#### Build Verification
- [ ] Release builds created successfully
- [ ] App signing configured correctly
- [ ] ProGuard/R8 optimization verified
- [ ] Binary size within acceptable limits
- [ ] No debug code in release builds

### Release Notes Template
```markdown
# Safe Gallery v1.0.0

## New Features
- Secure photo presentation with device locking
- Multi-collection support
- Auto-advance slideshow
- Platform-adaptive UI

## Improvements
- Enhanced performance for large photo collections
- Improved thumbnail generation
- Better error handling

## Bug Fixes
- Fixed photo ordering issues
- Resolved memory leaks in presentation mode
- Corrected theme switching behavior

## Platform Specific
### Android
- Device admin integration for secure locking
- Immersive mode improvements

### iOS
- Guided Access setup instructions
- Enhanced photo library integration

## Known Issues
- Some Android OEMs may restrict device admin functionality
- iOS requires manual Guided Access setup for full security
```

## Continuous Integration/Deployment

### GitHub Actions Workflow
**File**: `.github/workflows/build.yml`

```yaml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-builds
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Install CocoaPods
        run: |
          cd ios
          pod install
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/Runner.app
```

### Automated Release Workflow
**File**: `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false
```

## Distribution Strategies

### Android Distribution

#### Google Play Store
```bash
# Build App Bundle
flutter build appbundle --release

# Upload to Play Console
# 1. Go to Google Play Console
# 2. Select app → Release → Production
# 3. Create new release
# 4. Upload app-release.aab
# 5. Complete store listing
# 6. Submit for review
```

#### Direct APK Distribution
```bash
# Build universal APK
flutter build apk --release

# Or build split APKs for smaller size
flutter build apk --release --split-per-abi

# Distribute via:
# - Direct download links
# - Enterprise distribution
# - Third-party app stores
```

### iOS Distribution

#### App Store
```bash
# Archive in Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Product → Archive
# 3. Distribute App → App Store Connect
# 4. Upload to App Store Connect
# 5. Complete app metadata
# 6. Submit for review
```

#### TestFlight (Beta Testing)
```bash
# Same archive process as App Store
# 1. Upload to App Store Connect
# 2. Go to TestFlight tab
# 3. Add internal/external testers
# 4. Distribute beta builds
```

## Performance Optimization

### Build Size Optimization

#### Android Optimization
```bash
# Enable R8 optimization
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
        }
    }
}

# Split APKs by architecture
flutter build apk --release --split-per-abi

# Analyze APK size
flutter build apk --analyze-size
```

#### iOS Optimization
```bash
# Enable bitcode (automatic in Xcode)
# Strip debug symbols in release builds
# Use app thinning (automatic in App Store)

# Analyze app size
flutter build ios --analyze-size
```

### Runtime Performance
```bash
# Profile build for performance testing
flutter build apk --profile
flutter build ios --profile

# Run with performance overlay
flutter run --profile --trace-startup
```

## Monitoring & Analytics

### Crash Reporting
```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^3.4.0
  firebase_core: ^2.15.0
```

### Performance Monitoring
```yaml
# pubspec.yaml
dependencies:
  firebase_performance: ^0.9.3
```

### Build Metrics
```bash
# Track build times
time flutter build apk --release

# Monitor binary sizes
ls -lh build/app/outputs/flutter-apk/
ls -lh build/ios/iphoneos/
```

This deployment and build specification ensures reliable, optimized builds across both Android and iOS platforms with proper CI/CD integration and distribution strategies.