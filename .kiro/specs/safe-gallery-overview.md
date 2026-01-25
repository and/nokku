# Safe Gallery - Project Overview Spec

## Project Summary

Safe Gallery is a cross-platform Flutter application designed for secure photo presentation. It allows users to create curated photo collections and present them in a secure, full-screen mode that prevents unauthorized exit without device locking.

## Core Features

### 📱 Collection Management
- Create unlimited named photo collections
- Import photos from device gallery, iCloud, Google Photos
- Share sheet integration for direct photo sharing from other apps
- Collection CRUD operations (create, rename, add photos, delete)

### 🎨 Presentation Mode
- Full-screen immersive photo viewing
- Horizontal swipe navigation with infinite loop
- Tap-on-sides navigation support
- Optional pinch-to-zoom functionality
- Optional photo counter display ("3 of 10")
- Auto-advance slideshow with configurable intervals
- Smooth 60fps transitions

### 🔒 Security Features
- **Android**: Device Admin integration for automatic device locking
- **iOS**: Guided Access mode support with instructions
- Intercepts back button, home gesture, and app switcher attempts
- Auto-lock timer for hands-free viewing
- Immediate device lock on exit attempts during presentation

### ⚙️ Customization Options
- Presentation settings (zoom, counter, auto-advance, auto-lock)
- Display settings (theme, animations)
- Platform-specific UI (Material Design for Android, Cupertino for iOS)

## Technical Architecture

### Framework & Dependencies
- **Flutter 3.x** - Cross-platform framework
- **Provider** - State management
- **SQLite (sqflite)** - Local database storage
- **photo_manager** - Photo library access
- **receive_sharing_intent** - Share sheet integration
- **Platform Channels** - Native device locking functionality

### Architecture Pattern
- **MVVM with Provider** pattern
- Clean separation of concerns across layers:
  - Models (data structures)
  - Services (business logic)
  - Providers (state management)
  - Screens (UI components)

### Platform-Specific Implementation
- **Android**: Device Admin API for device locking
- **iOS**: Guided Access recommendations (no programmatic locking)
- Adaptive UI components for platform consistency

## Project Structure

```
lib/
├── models/              # Data models
│   ├── collection.dart
│   ├── photo_item.dart
│   └── app_settings.dart
├── services/            # Business logic
│   ├── database_service.dart
│   ├── photo_service.dart
│   ├── lock_service.dart
│   └── settings_service.dart
├── providers/           # State management
│   └── app_provider.dart
├── screens/             # UI screens
│   ├── collections_screen.dart
│   ├── presentation_screen.dart
│   ├── photo_picker_screen.dart
│   └── settings_screen.dart
└── main.dart           # App entry point
```

## Key Design Decisions

1. **Flutter over Native**: Single codebase with excellent performance
2. **SQLite for Storage**: Reliable local storage with complex query support
3. **Platform Channels**: Native Android/iOS APIs for device control
4. **Provider for State**: Simple, efficient state management
5. **Lazy Loading**: Memory-efficient image loading
6. **Platform-Adaptive UI**: Native look and feel on each platform

## Security & Privacy

- **Local Storage Only**: No cloud sync, all data stored locally
- **No Analytics**: Zero tracking or data collection
- **Read-Only Photo Access**: Only reads from photo library
- **Device Lock Integration**: Prevents unauthorized access during presentation

## Performance Optimizations

- Lazy image loading with thumbnail generation
- Image caching via photo_manager
- Database indexing for fast queries
- Smooth animations targeting 60fps
- Minimal background processing for battery optimization

## Development Setup Requirements

- Flutter SDK 3.0.0+
- Android Studio (for Android development)
- Xcode 14+ (for iOS development, macOS only)
- CocoaPods (for iOS dependencies)

## Build Targets

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Release Formats**: APK/AAB for Android, IPA for iOS

This spec provides the foundation for understanding the Safe Gallery project structure, features, and technical implementation details.