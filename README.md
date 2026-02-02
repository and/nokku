# Nokku temp gallery

A cross-platform (iOS & Android) Flutter app for creating curated photo galleries with secure presentation mode. When presenting photos, viewers see only selected photos and cannot exit without locking the device.

## Features

### ✨ Core Functionality

- **Photo Collections**: Create unlimited named collections with unlimited photos
- **Multi-source Import**: Add photos from local gallery, iCloud, Google Photos, or any source
- **Share Sheet Integration**: Share photos directly from any app to Nokku temp gallery
- **Secure Presentation Mode**: Full-screen, immersive photo viewing with device lock on exit
- **Native Feel**: Platform-specific UI (iOS Photos style / Android Gallery style)

### 🎨 Presentation Features

- Native horizontal swipe navigation (infinite loop)
- Tap-on-sides support for navigation
- Optional pinch-to-zoom
- Optional photo counter ("3 of 10")
- Auto-advance slideshow with configurable intervals
- Auto-lock timer for hands-free viewing
- Smooth, 60fps transitions

### 🔒 Security Features

- **Android**: Device Admin integration for automatic device locking on exit attempts
- **iOS**: Guided Access mode support with in-app instructions
- Intercepts back button, home gesture, and app switcher attempts
- Immediate device lock on any exit attempt during presentation

### ⚙️ Customization

**Presentation Settings:**
- Pinch-to-zoom: On/Off (default: Off)
- Photo counter: Show/Hide (default: Hide)
- Auto-advance: On/Off with intervals (3s, 5s, 10s, 30s)
- Auto-lock timer: 1, 2, 5, 10, 15 minutes or disabled

**Display Settings:**
- Theme: System/Light/Dark
- Transition animations: Enable/Disable

## Installation & Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Xcode 14+ (for iOS development)
- Android Studio / Android SDK (for Android development)
- CocoaPods (for iOS dependencies)

### Setup Steps

1. **Clone and navigate to the project**:
   ```bash
   cd safe_gallery
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **iOS Setup**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run on device/emulator**:
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

### Platform-Specific Configuration

#### Android

**Device Admin Permission (Required for device locking)**:

1. After installing the app, go to Settings
2. Tap "Device Admin" under Security section
3. Grant device admin permission
4. Now the app can lock your device when exiting presentation mode

**Permissions**:
- Photo library access: Requested on first launch
- Device admin: Manually enabled in Settings

#### iOS

**Guided Access Setup (Recommended for full security)**:

1. Go to iOS Settings > Accessibility > Guided Access
2. Toggle Guided Access ON
3. Set a passcode
4. When in presentation mode:
   - Triple-click home/side button to start Guided Access
   - Triple-click again to exit (requires passcode)

**Permissions**:
- Photo library access: Requested on first launch

## Usage

### Creating a Collection

1. Open Nokku temp gallery
2. Tap the "+" button (Android) or "Create Collection" (iOS)
3. Enter a collection name
4. Select photos from your gallery
5. Tap "Add" to save

### Viewing in Presentation Mode

1. Tap a collection from the home screen
2. App enters full-screen presentation mode
3. Swipe left/right to navigate (infinite loop)
4. Tap left/right sides to navigate
5. Long-press the close button (top-right) to exit and lock device

### Using Share Sheet

1. Open any app with photos (Gallery, WhatsApp, etc.)
2. Select photos and tap "Share"
3. Choose "Nokku temp gallery"
4. Photos open immediately in presentation mode

### Managing Collections

**Rename**: Long-press collection → "Rename"
**Add Photos**: Long-press collection → "Add Photos"
**Delete**: Long-press collection → "Delete"

## Architecture

### Project Structure

```
safe_gallery/
├── lib/
│   ├── models/              # Data models
│   │   ├── collection.dart
│   │   ├── photo_item.dart
│   │   └── app_settings.dart
│   ├── services/            # Business logic
│   │   ├── database_service.dart
│   │   ├── photo_service.dart
│   │   ├── lock_service.dart
│   │   └── settings_service.dart
│   ├── providers/           # State management
│   │   └── app_provider.dart
│   ├── screens/             # UI screens
│   │   ├── collections_screen.dart
│   │   ├── presentation_screen.dart
│   │   ├── photo_picker_screen.dart
│   │   └── settings_screen.dart
│   └── main.dart
├── android/
│   └── app/src/main/kotlin/com/safegallery/
│       ├── MainActivity.kt           # Platform channel implementation
│       └── DeviceAdminReceiver.kt    # Device admin receiver
└── ios/
    └── Runner/
        └── AppDelegate.swift         # Platform channel implementation
```

### Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Photo Access**: photo_manager
- **Share Intent**: receive_sharing_intent
- **Platform Channels**: Custom implementation for device locking

### Key Design Decisions

1. **Flutter over Native**: Single codebase, excellent performance, rich widget library
2. **SQLite for Storage**: Reliable, fast, supports complex queries for collections
3. **Platform Channels for Locking**: Native Android/iOS APIs for device control
4. **Provider for State**: Simple, efficient, recommended by Flutter team
5. **Lazy Loading**: Images loaded on-demand for memory efficiency

## Performance Optimizations

- **Lazy Image Loading**: Photos loaded only when visible
- **Thumbnail Generation**: 200x200 thumbnails for grid views
- **Image Caching**: Automatic caching via photo_manager
- **60fps Target**: Smooth animations and transitions
- **Battery Optimization**: Minimal background processing

## Security & Privacy

- **Local Storage Only**: All data stored locally, no cloud sync
- **No Analytics**: Zero tracking or data collection
- **Photo Access**: Read-only access to photo library
- **Device Lock**: Prevents unauthorized access during presentation

## Limitations & Known Issues

### iOS Limitations

- **Cannot programmatically lock device**: iOS security restriction
- **Requires Guided Access**: User must manually enable for full lock mode
- **System gestures**: Cannot fully block without Guided Access

### Android Limitations

- **Requires Device Admin**: User must grant permission manually
- **Some launchers**: May bypass lock on certain custom Android launchers

## Troubleshooting

### Device won't lock on Android

**Solution**: Enable Device Admin in Settings → Security → Device Admin

### Photos not showing

**Solution**: Grant photo library permission in device settings

### Share sheet not working

**Solution**: Reinstall app (share intent registered during installation)

### App exits without locking on iOS

**Solution**: Enable and use Guided Access (triple-click home button)

## Building for Release

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and archive.

## Future Enhancements

- [ ] Cloud backup for collections (optional)
- [ ] Password protection for individual collections
- [ ] Video support
- [ ] Collection sharing (export/import)
- [ ] Multiple themes
- [ ] Advanced editing (crop, rotate)
- [ ] Photo metadata display

## Contributing

This is a personal project, but suggestions and bug reports are welcome!

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Open an issue on GitHub
- Check the troubleshooting section above

---

**Built with Flutter** ❤️ for iOS and Android
