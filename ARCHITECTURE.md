# Safe Gallery - Architecture Documentation

## Overview

Safe Gallery is a Flutter-based cross-platform mobile application designed to provide secure, curated photo presentations. This document outlines the architectural decisions, patterns, and technical implementation details.

## Architecture Pattern

### MVVM (Model-View-ViewModel) with Provider

```
┌─────────────────────────────────────────────────────────┐
│                         View Layer                       │
│  (Screens: Collections, Presentation, PhotoPicker, etc) │
└──────────────────┬──────────────────────────────────────┘
                   │ watches
                   ▼
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Layer                       │
│              (AppProvider - State Management)            │
└──────────────────┬──────────────────────────────────────┘
                   │ uses
                   ▼
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  (DatabaseService, PhotoService, LockService, etc)      │
└──────────────────┬──────────────────────────────────────┘
                   │ manipulates
                   ▼
┌─────────────────────────────────────────────────────────┐
│                      Model Layer                         │
│        (Collection, PhotoItem, AppSettings)              │
└─────────────────────────────────────────────────────────┘
```

## Layer Breakdown

### 1. Model Layer (`lib/models/`)

**Responsibilities**:
- Pure data structures
- No business logic
- Serialization/deserialization

**Files**:
- `collection.dart`: Photo collection model
- `photo_item.dart`: Individual photo model
- `app_settings.dart`: User preferences model

**Example**:
```dart
class Collection {
  final String id;
  final String name;
  final List<PhotoItem> photos;

  // Serialization methods
  Map<String, dynamic> toMap() { ... }
  factory Collection.fromMap(Map<String, dynamic> map) { ... }
}
```

### 2. Service Layer (`lib/services/`)

**Responsibilities**:
- Business logic
- Data access and persistence
- External API communication
- Platform-specific implementations

**Files**:

#### `database_service.dart`
- SQLite database management
- CRUD operations for collections and photos
- Database schema management

```dart
class DatabaseService {
  Future<List<Collection>> getCollections()
  Future<void> insertCollection(Collection collection)
  Future<void> updateCollection(Collection collection)
  Future<void> deleteCollection(String id)
}
```

#### `photo_service.dart`
- Photo library access via `photo_manager`
- Asset to PhotoItem conversion
- Thumbnail generation

```dart
class PhotoService {
  Future<bool> requestPermission()
  Future<List<AssetPathEntity>> getAlbums()
  Future<List<PhotoItem>> convertAssetsToPhotoItems(List<AssetEntity> assets)
}
```

#### `lock_service.dart`
- Platform channel communication
- Device locking functionality
- Presentation mode management
- Auto-lock timer

```dart
class LockService {
  Future<void> enterPresentationMode()
  Future<void> lockDevice()
  void startAutoLockTimer(int minutes)
}
```

#### `settings_service.dart`
- Shared preferences management
- Settings persistence
- Settings retrieval

### 3. ViewModel Layer (`lib/providers/`)

**Responsibilities**:
- State management
- UI logic
- Coordinate between services and views

**Files**:

#### `app_provider.dart`
- Global app state
- Collection management
- Settings management
- Notifies UI of changes

```dart
class AppProvider with ChangeNotifier {
  List<Collection> _collections = [];
  AppSettings _settings = AppSettings();

  Future<void> createCollection(String name, List<PhotoItem> photos)
  Future<void> updateSettings(AppSettings newSettings)

  // Notifies listeners when state changes
}
```

### 4. View Layer (`lib/screens/`)

**Responsibilities**:
- UI rendering
- User interaction handling
- Platform-specific UI (Material vs Cupertino)

**Files**:

#### `collections_screen.dart`
- Home screen
- Collection grid display
- Create/edit/delete collections
- Platform-adaptive UI (Material + Cupertino)

#### `presentation_screen.dart`
- Full-screen photo viewer
- Swipe navigation
- Infinite loop
- Lock behavior handling
- Auto-advance slideshow

#### `photo_picker_screen.dart`
- Album selection
- Multi-photo selection
- Thumbnail grid
- Platform-adaptive UI

#### `settings_screen.dart`
- User preferences UI
- Device admin management
- Guided Access instructions

## Data Flow

### Creating a Collection

```
User taps "Create Collection"
         ↓
CollectionsScreen shows name dialog
         ↓
Navigate to PhotoPickerScreen
         ↓
User selects photos from PhotoService
         ↓
PhotoService converts AssetEntity → PhotoItem
         ↓
Call AppProvider.createCollection()
         ↓
AppProvider → DatabaseService.insertCollection()
         ↓
DatabaseService saves to SQLite
         ↓
AppProvider notifies listeners
         ↓
CollectionsScreen rebuilds with new collection
```

### Presentation Mode Flow

```
User taps collection
         ↓
Navigate to PresentationScreen
         ↓
PresentationScreen.initState():
  - Register lifecycle observer
  - Enter presentation mode (LockService)
  - Set up auto-advance timer
  - Hide system UI
         ↓
User swipes photos (PageView)
         ↓
User presses home/back button
         ↓
WidgetsBindingObserver.didChangeAppLifecycleState()
         ↓
State = paused → LockService.lockDevice()
         ↓
Platform channel → Native code
         ↓
Device locks
```

## Platform Channels

### Android Implementation

**Dart → Kotlin**:

```dart
// lib/services/lock_service.dart
static const MethodChannel _channel = MethodChannel('com.safegallery/lock');
await _channel.invokeMethod('lockDevice');
```

**Kotlin Native Code**:

```kotlin
// android/.../MainActivity.kt
MethodChannel(flutterEngine.dartExecutor, "com.safegallery/lock")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "lockDevice" -> {
                devicePolicyManager.lockNow()
                result.success(true)
            }
        }
    }
```

### iOS Implementation

**Dart → Swift**:

```dart
// Same Dart code as Android
await _channel.invokeMethod('lockDevice');
```

**Swift Native Code**:

```swift
// ios/Runner/AppDelegate.swift
let lockChannel = FlutterMethodChannel(name: "com.safegallery/lock", ...)
lockChannel.setMethodCallHandler { (call, result) in
    switch call.method {
    case "lockDevice":
        // iOS cannot programmatically lock
        result(false)
    }
}
```

## Database Schema

### SQLite Tables

#### `collections`
```sql
CREATE TABLE collections (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
)
```

#### `photos`
```sql
CREATE TABLE photos (
    id TEXT PRIMARY KEY,
    collectionId TEXT NOT NULL,
    path TEXT NOT NULL,
    thumbnailPath TEXT,
    addedAt TEXT NOT NULL,
    photoOrder INTEGER NOT NULL,
    FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
)

CREATE INDEX idx_photos_collection ON photos(collectionId)
```

### Relationships

- One collection → Many photos (1:N)
- Foreign key constraint ensures referential integrity
- Cascade delete removes photos when collection is deleted

## State Management

### Provider Pattern

**Why Provider?**
- Officially recommended by Flutter team
- Simple, minimal boilerplate
- Excellent performance
- Easy to test

**Implementation**:

```dart
// main.dart
ChangeNotifierProvider(
  create: (_) => AppProvider()..initialize(),
  child: SafeGalleryApp(),
)

// In widgets
final provider = context.watch<AppProvider>();
final collections = provider.collections;

// Update state
context.read<AppProvider>().createCollection(...);
```

### State Flow

```
User Action → Screen → Provider Method → Service Layer → Data Layer
                 ↑                                           ↓
                 ←←←←←←←← notifyListeners() ←←←←←←←←←←←←←←←←
```

## Performance Optimizations

### 1. Lazy Loading

- Photos loaded on-demand using `PageView.builder`
- Only visible photos are rendered
- Reduces memory footprint

### 2. Thumbnail Caching

```dart
// Thumbnails generated and cached
final thumbFile = await asset.thumbDataWithSize(200, 200);
```

### 3. Image Optimization

- `InteractiveViewer` for pinch-to-zoom (optional)
- `AnimatedOpacity` for smooth transitions
- `frameBuilder` for progressive loading

### 4. Database Indexing

```sql
CREATE INDEX idx_photos_collection ON photos(collectionId)
```

### 5. Widget Rebuilds

- `const` constructors where possible
- Selective rebuilding with `Consumer` widgets
- `ListView.builder` / `GridView.builder` for large lists

## Security Considerations

### 1. Local Storage Only

- No cloud sync
- No external API calls
- All data stored in SQLite

### 2. Photo Access Permissions

- Request only necessary permissions
- Runtime permission requests
- Graceful degradation if denied

### 3. Device Locking

**Android**:
- Requires Device Admin permission
- Uses `DevicePolicyManager.lockNow()`
- Immersive mode prevents accidental exits

**iOS**:
- Recommends Guided Access
- Cannot programmatically lock
- App lifecycle observer detects backgrounding

### 4. No Screenshot Blocking

- Intentionally not blocked
- Owner controls the device
- Focus on preventing exit, not capture

## Testing Strategy

### Unit Tests

- Model serialization/deserialization
- Service layer business logic
- Provider state management

### Integration Tests

- Database CRUD operations
- Photo service workflows
- Settings persistence

### Widget Tests

- Screen rendering
- User interactions
- Navigation flows

### Platform Tests

- Android device locking
- iOS lifecycle handling
- Share intent integration

## Dependencies

### Core Flutter

- `flutter`: Framework
- `flutter/cupertino`: iOS-style widgets
- `flutter/material`: Android-style widgets

### State Management

- `provider`: State management

### Data & Storage

- `sqflite`: SQLite database
- `shared_preferences`: Simple key-value storage
- `path_provider`: File system paths

### Photo Access

- `photo_manager`: Photo library access
- `image_picker`: Alternative photo picker
- `cached_network_image`: Image caching
- `flutter_cache_manager`: Cache management

### Platform Integration

- `receive_sharing_intent`: Share sheet

### Utilities

- `uuid`: Unique ID generation
- `intl`: Internationalization

## Build & Release

### Android

**Build Types**:
- Debug: Development with hot reload
- Release: Optimized, signed APK/AAB

**Gradle Configuration**:
- Min SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Kotlin: 1.9.0

### iOS

**Requirements**:
- iOS 12.0+
- CocoaPods for dependencies

**Build Configuration**:
- Swift 5+
- Auto-signing via Xcode

## Future Architecture Improvements

1. **Modular Architecture**: Break into feature modules
2. **Repository Pattern**: Abstract data sources
3. **Dependency Injection**: Use get_it or riverpod
4. **Bloc/Cubit**: More robust state management for complex features
5. **Code Generation**: Freezed for immutable models
6. **API Layer**: If cloud sync added in future

## Conclusion

Safe Gallery follows Flutter best practices with a clean, layered architecture. The separation of concerns makes it maintainable, testable, and extensible. Platform channels enable native functionality while keeping the codebase mostly Dart.

The architecture prioritizes:
- **Simplicity**: Minimal abstractions
- **Performance**: Lazy loading, caching, indexing
- **Maintainability**: Clear separation of concerns
- **Platform Integration**: Native Android/iOS feel
