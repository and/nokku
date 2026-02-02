# Nokku temp gallery - Codebase Knowledge

*Generated from comprehensive source code analysis - Last updated: January 25, 2026*

## Project Overview

Nokku temp gallery is a cross-platform Flutter application for secure photo and video presentation. Users create curated collections and present them in full-screen mode with device locking security features.

## Architecture Summary

### Design Pattern
- **MVVM with Provider** for state management
- Clean separation: Models → Services → Providers → Screens
- Platform-adaptive UI (Material Design/Cupertino)

### Key Dependencies
```yaml
# State Management
provider: ^6.1.0

# Local Storage
sqflite: ^2.3.0
shared_preferences: ^2.2.2

# Media Access
photo_manager: ^3.0.0
video_player: ^2.8.1

# Utilities
uuid: ^4.2.1
```

## Core Data Models

### Collection
```dart
class Collection {
  final String id;
  final String name;
  final DateTime createdAt, updatedAt;
  final List<PhotoItem> photos;
  
  // Key methods: toMap(), fromMap(), copyWith()
  // Computed: thumbnailPath, photoCount
}
```

### PhotoItem
```dart
class PhotoItem {
  final String id, path;
  final String? thumbnailPath;
  final DateTime addedAt;
  final int order;
  final MediaType mediaType; // image | video
  
  // Computed: isVideo, isImage
}
```

### AppSettings
```dart
class AppSettings {
  // Presentation settings
  final bool pinchToZoom, showPhotoCounter, autoAdvance;
  final int autoAdvanceInterval, autoLockMinutes;
  final bool confirmPhotoRemoval, swipeToDelete;
  
  // Display settings
  final AppThemeMode themeMode; // system | light | dark
  final bool transitionAnimations;
}
```

## Service Layer

### DatabaseService (SQLite)
- **Tables**: `collections`, `photos` with foreign key relationship
- **Operations**: Full CRUD for collections and photos
- **Indexing**: `idx_photos_collection` for performance
- **Singleton pattern** with lazy initialization

### PhotoService
- **Photo Manager Integration**: Album access, asset conversion
- **Thumbnail Generation**: 200x200 thumbnails in temp directory
- **Permission Handling**: Requests photo library access
- **Asset Conversion**: AssetEntity → PhotoItem with UUID generation

### LockService (Platform Channels)
- **Channel**: `com.safegallery/lock`
- **Android Methods**: Device admin integration, immediate locking
- **iOS Methods**: Guided Access support (manual setup required)
- **Auto-lock Timer**: Configurable timeout with reset capability
- **Presentation Mode**: Enter/exit with system UI control

### SettingsService
- **Storage**: SharedPreferences with JSON serialization
- **Operations**: Load, save, reset settings
- **Error Handling**: Graceful fallback to defaults

### IntentService (Android Only)
- **Channel**: `com.safegallery/intent`
- **Share Integration**: Receives photos from other apps
- **Permission Management**: Storage permission requests
- **File Handling**: Shared content processing and cleanup

## State Management (AppProvider)

### Core State
```dart
class AppProvider extends ChangeNotifier {
  List<Collection> _collections = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = false;
  
  // Getters: collections, settings, isLoading
}
```

### Key Operations
- **Collection Management**: Create, update, delete, reorder photos
- **Settings Management**: Update and persist user preferences
- **Initialization**: Parallel loading of collections and settings
- **Photo Operations**: Add/remove photos with order management

## Screen Architecture

### CollectionsScreen
- **Platform Variants**: Android (Material) + iOS (Cupertino)
- **Features**: Grid view, collection options, quick present mode
- **Navigation**: Settings, photo picker, presentation mode
- **Exit Handling**: Device lock confirmation dialog

### PresentationScreen
- **Core Features**: Full-screen photo/video viewing with infinite scroll
- **Navigation**: Swipe, tap zones (left/right thirds), auto-advance
- **Security**: PopScope prevention, device lock on exit
- **Media Support**: Images with InteractiveViewer, videos with custom player
- **Temporary Collections**: Save dialog for shared content
- **Photo Management**: Swipe-to-delete with confirmation options

### PhotoPickerScreen
- **Album Selection**: Dropdown (Android) / Modal (iOS)
- **Multi-selection**: Grid with visual selection indicators
- **Modes**: Normal save vs Quick Present (temporary collections)
- **Permission Handling**: Photo library access with error dialogs

### SettingsScreen
- **Platform Variants**: Material ListTiles vs Cupertino sections
- **Categories**: Presentation, Display, Security, About
- **Controls**: Switches, dropdowns, pickers for all settings
- **Platform-specific**: Device Admin (Android) vs Guided Access info (iOS)

## Video Playback System

### VideoPlayerWidget
- **Error Handling**: File existence, permissions, format validation
- **Controls**: Play/pause, progress bar, time display
- **Auto-hide**: Controls fade after 3 seconds
- **Debugging**: Comprehensive logging for troubleshooting
- **Retry Logic**: User-initiated retry on errors

## Platform-Specific Features

### Android
- **Device Admin**: Automatic device locking via DeviceAdminReceiver
- **Share Intent**: Receives photos from other apps
- **Material Design**: Native Android UI patterns
- **Permissions**: Photo library, device admin, storage

### iOS
- **Guided Access**: Manual setup instructions for full security
- **Cupertino Design**: Native iOS UI patterns
- **Limitations**: No programmatic device locking
- **Share Extension**: Receives content from other apps

## Security Implementation

### Presentation Mode Security
- **System UI**: Hidden during presentation (immersive mode)
- **Navigation Prevention**: PopScope with custom handling
- **Exit Confirmation**: Lock device before showing dialogs
- **Auto-lock**: Configurable timer with user interaction reset

### Data Security
- **Local Storage Only**: No cloud sync or external transmission
- **No Analytics**: Zero tracking or data collection
- **Read-only Access**: Photo library permissions
- **Temporary Files**: Thumbnails in system temp directory

## Performance Optimizations

### Image Handling
- **Lazy Loading**: Photos loaded on-demand during presentation
- **Thumbnail Caching**: 200x200 thumbnails for grid views
- **Memory Management**: Automatic cleanup via photo_manager
- **Error Handling**: Graceful fallback for missing/corrupted files

### Database Performance
- **Indexing**: Collection-based photo queries
- **Batch Operations**: Efficient photo updates
- **Connection Management**: Singleton pattern with lazy initialization

### UI Performance
- **60fps Target**: Smooth animations and transitions
- **Platform Optimization**: Native UI components
- **State Management**: Efficient Provider notifications

## Error Handling Patterns

### Service Layer
- **Try-catch blocks** with debug logging
- **Graceful degradation** for permission failures
- **Default fallbacks** for corrupted data

### UI Layer
- **Loading states** with progress indicators
- **Error dialogs** with user-friendly messages
- **Retry mechanisms** for recoverable failures

## File Structure Summary

```
lib/
├── main.dart                    # App entry, theme handling, shared content
├── models/                      # Data structures
│   ├── collection.dart         # Collection with photos
│   ├── photo_item.dart         # Photo/video items with metadata
│   └── app_settings.dart       # User preferences
├── services/                    # Business logic layer
│   ├── database_service.dart   # SQLite operations
│   ├── photo_service.dart      # Photo manager integration
│   ├── lock_service.dart       # Platform channel security
│   ├── settings_service.dart   # SharedPreferences wrapper
│   └── intent_service.dart     # Android share integration
├── providers/                   # State management
│   └── app_provider.dart       # Main app state with ChangeNotifier
├── screens/                     # UI screens
│   ├── collections_screen.dart # Main grid view with platform variants
│   ├── presentation_screen.dart # Full-screen photo/video viewer
│   ├── photo_picker_screen.dart # Album selection and photo picking
│   └── settings_screen.dart    # Configuration with platform variants
└── widgets/                     # Reusable components
    └── video_player_widget.dart # Custom video player with controls
```

## Development Notes

### Platform Channels
- **Lock Service**: `com.safegallery/lock` for device security
- **Intent Service**: `com.safegallery/intent` for Android sharing
- **Native Code**: Kotlin (Android) + Swift (iOS) implementations

### Testing Considerations
- **Permission Testing**: Photo library access on both platforms
- **Device Admin**: Android security feature testing
- **Share Integration**: Test receiving content from various apps
- **Video Formats**: Ensure compatibility across platforms

### Future Enhancement Areas
- **Cloud Backup**: Optional collection synchronization
- **Password Protection**: Individual collection security
- **Advanced Editing**: Crop, rotate, metadata display
- **Collection Sharing**: Export/import functionality

## Common Issues & Solutions

### Video Playback
- **File Permissions**: Check file existence and read access
- **Format Support**: MP4 recommended for cross-platform compatibility
- **Error Recovery**: Comprehensive error handling with retry logic

### Device Locking
- **Android**: Requires manual Device Admin permission grant
- **iOS**: Requires manual Guided Access setup
- **Testing**: Use physical devices for security feature testing

### Photo Access
- **Permissions**: Handle graceful degradation when denied
- **Large Libraries**: Implement pagination for performance
- **Thumbnails**: Automatic generation and cleanup

This knowledge base provides a comprehensive understanding of the Nokku temp gallery codebase without requiring full source code analysis.