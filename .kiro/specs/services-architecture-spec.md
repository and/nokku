# Safe Gallery - Services Architecture Specification

## Overview

The services layer implements the business logic and data access patterns for Safe Gallery. Each service follows the singleton pattern and provides a clean API for specific functionality domains.

## Service Architecture Principles

### Design Patterns
- **Singleton Pattern**: Single instance per service for consistency
- **Separation of Concerns**: Each service handles one domain
- **Async/Await**: All operations are asynchronous
- **Error Handling**: Graceful error handling with meaningful messages
- **Platform Abstraction**: Services abstract platform-specific implementations

### Service Dependencies
```
AppProvider (State Management)
    ↓
Services Layer (Business Logic)
    ↓
Platform APIs / Storage (Data Layer)
```

## Core Services

### 1. DatabaseService

**File**: `lib/services/database_service.dart`

**Purpose**: Manages SQLite database operations for collections and photos.

**Responsibilities**:
- Database initialization and schema management
- CRUD operations for collections and photos
- Relationship management (collection ↔ photos)
- Database migrations and versioning

**Key Methods**:

#### Database Management
```dart
Future<Database> get database  // Lazy database initialization
Future<Database> _initDatabase()  // Creates database and tables
Future<void> _onCreate(Database db, int version)  // Schema creation
```

#### Collection Operations
```dart
Future<List<Collection>> getCollections()  // Get all collections with photos
Future<Collection?> getCollection(String id)  // Get single collection
Future<void> insertCollection(Collection collection)  // Create new collection
Future<void> updateCollection(Collection collection)  // Update collection metadata
Future<void> deleteCollection(String id)  // Delete collection and photos
```

#### Photo Operations
```dart
Future<List<PhotoItem>> getPhotosForCollection(String collectionId)  // Get ordered photos
Future<void> insertPhoto(String collectionId, PhotoItem photo)  // Add single photo
Future<void> updatePhotos(String collectionId, List<PhotoItem> photos)  // Batch update
Future<void> deletePhoto(String photoId)  // Remove single photo
```

**Database Schema**:
```sql
-- Collections table
CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Photos table with foreign key
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  collectionId TEXT NOT NULL,
  path TEXT NOT NULL,
  thumbnailPath TEXT,
  addedAt TEXT NOT NULL,
  photoOrder INTEGER NOT NULL,
  FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
);

-- Performance index
CREATE INDEX idx_photos_collection ON photos(collectionId);
```

**Error Handling**:
- Database connection failures
- SQL constraint violations
- File system access errors
- Graceful degradation for corrupted data

### 2. PhotoService

**File**: `lib/services/photo_service.dart`

**Purpose**: Handles photo library access and asset management.

**Responsibilities**:
- Photo library permission management
- Album and photo enumeration
- Asset to PhotoItem conversion
- Thumbnail generation and caching

**Key Methods**:

#### Permission Management
```dart
Future<bool> requestPermission()  // Request photo library access
```

#### Album Operations
```dart
Future<List<AssetPathEntity>> getAlbums()  // Get all photo albums
Future<List<AssetEntity>> getPhotosFromAlbum(AssetPathEntity album, {int page, int size})  // Paginated photo loading
```

#### Asset Conversion
```dart
Future<PhotoItem?> assetToPhotoItem(AssetEntity asset, int order)  // Convert single asset
Future<List<PhotoItem>> convertAssetsToPhotoItems(List<AssetEntity> assets)  // Batch conversion
```

**Thumbnail Generation**:
- 200x200 pixel thumbnails for grid views
- Cached in system temp directory
- Automatic cleanup on app restart
- Fallback to original image if thumbnail fails

**Platform Integration**:
- Uses `photo_manager` plugin for cross-platform access
- Handles iOS/Android permission differences
- Supports iCloud and Google Photos integration

### 3. LockService

**File**: `lib/services/lock_service.dart`

**Purpose**: Manages presentation mode and device locking functionality.

**Responsibilities**:
- Presentation mode state management
- Platform-specific device locking
- Auto-lock timer management
- System UI control

**Key Methods**:

#### Presentation Mode
```dart
Future<void> enterPresentationMode()  // Enable immersive mode
Future<void> exitPresentationMode()  // Restore normal UI
bool get isPresentationMode  // Current state getter
```

#### Device Locking
```dart
Future<void> lockDevice()  // Lock device immediately
Future<bool> isDeviceAdminEnabled()  // Check Android device admin status
Future<void> requestDeviceAdmin()  // Request Android device admin permission
```

#### Auto-Lock Timer
```dart
void startAutoLockTimer(int minutes)  // Start countdown timer
void resetAutoLockTimer(int minutes)  // Reset timer on user interaction
void _cancelAutoLockTimer()  // Cancel active timer
```

**Platform Channel Communication**:
```dart
static const MethodChannel _channel = MethodChannel('com.safegallery/lock');
```

**Platform-Specific Behavior**:

#### Android Implementation
- Device Admin API for device locking
- Immersive mode for full-screen presentation
- FLAG_KEEP_SCREEN_ON during presentation
- DevicePolicyManager.lockNow() for immediate locking

#### iOS Implementation
- Cannot programmatically lock device (iOS security restriction)
- Guided Access mode recommendations
- Status bar hiding during presentation
- UIApplication.isIdleTimerDisabled for screen management

### 4. SettingsService

**File**: `lib/services/settings_service.dart`

**Purpose**: Manages user preferences persistence and retrieval.

**Responsibilities**:
- Settings serialization/deserialization
- SharedPreferences integration
- Default value management
- Settings validation

**Key Methods**:

#### Settings Operations
```dart
Future<AppSettings> loadSettings()  // Load from SharedPreferences
Future<void> saveSettings(AppSettings settings)  // Persist to SharedPreferences
Future<void> resetSettings()  // Clear all settings (restore defaults)
```

**Storage Implementation**:
- Uses SharedPreferences for cross-platform persistence
- JSON serialization for complex data structures
- Graceful fallback to defaults on parse errors
- Atomic updates to prevent corruption

**Settings Key**: `'app_settings'`

**Error Handling**:
- JSON parse errors → fallback to defaults
- SharedPreferences access errors → graceful degradation
- Invalid setting values → validation and correction

## Service Integration Patterns

### Dependency Injection
```dart
class AppProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  final PhotoService _photoService = PhotoService();
  final LockService _lockService = LockService();
}
```

### Error Propagation
- Services throw specific exceptions
- AppProvider catches and handles errors
- UI displays user-friendly error messages
- Logging for debugging purposes

### Async Operations
- All service methods are async
- Proper await/async usage throughout
- Loading states managed by AppProvider
- UI shows progress indicators during operations

## Platform Channel Architecture

### Channel Definition
```dart
static const MethodChannel _channel = MethodChannel('com.safegallery/lock');
```

### Method Calls
```dart
// Dart → Native
await _channel.invokeMethod('lockDevice');
await _channel.invokeMethod('enterPresentationMode');
await _channel.invokeMethod('isDeviceAdminEnabled');
```

### Native Implementation

#### Android (Kotlin)
```kotlin
MethodChannel(flutterEngine.dartExecutor, CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "lockDevice" -> {
                devicePolicyManager.lockNow()
                result.success(true)
            }
        }
    }
```

#### iOS (Swift)
```swift
lockChannel.setMethodCallHandler { (call, result) in
    switch call.method {
    case "lockDevice":
        // iOS cannot programmatically lock
        result(false)
    }
}
```

## Performance Considerations

### Database Optimization
- Indexed queries for fast collection retrieval
- Batch operations for photo updates
- Connection pooling and reuse
- Lazy loading of photo data

### Memory Management
- Thumbnail caching with size limits
- Asset disposal after conversion
- Timer cleanup on service disposal
- Weak references where appropriate

### Background Processing
- Minimal background operations
- Efficient thumbnail generation
- Async/await for non-blocking operations
- Platform-specific optimizations

## Testing Strategy

### Unit Tests
- Mock platform channels for testing
- Database operations with in-memory SQLite
- Settings serialization/deserialization
- Error handling scenarios

### Integration Tests
- End-to-end service workflows
- Platform channel communication
- Database schema migrations
- Photo library access flows

This services architecture provides a robust foundation for the Safe Gallery application with clear separation of concerns and platform-specific optimizations.