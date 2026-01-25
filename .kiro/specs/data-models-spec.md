# Safe Gallery - Data Models Specification

## Overview

This spec defines the core data models used throughout the Safe Gallery application. All models follow consistent patterns for serialization, immutability, and data validation.

## Model Architecture Principles

### Design Patterns
- **Immutable Data Structures**: All models use `copyWith()` methods for updates
- **Serialization Support**: `toMap()` and `fromMap()` methods for persistence
- **Type Safety**: Strong typing with null safety
- **Validation**: Built-in data validation where appropriate

### Naming Conventions
- Model classes use PascalCase (e.g., `PhotoItem`)
- Properties use camelCase (e.g., `createdAt`)
- Database fields use snake_case (e.g., `created_at`)

## Core Models

### 1. Collection Model

**File**: `lib/models/collection.dart`

**Purpose**: Represents a photo collection with metadata and associated photos.

**Properties**:
```dart
class Collection {
  final String id;           // UUID identifier
  final String name;         // User-defined collection name
  final DateTime createdAt;  // Creation timestamp
  final DateTime updatedAt;  // Last modification timestamp
  final List<PhotoItem> photos; // Associated photos (default: empty)
}
```

**Key Methods**:
- `toMap()` - Serializes to Map for database storage
- `fromMap(Map<String, dynamic> map, {List<PhotoItem>? photos})` - Deserializes from database
- `copyWith()` - Creates modified copy (immutable updates)

**Computed Properties**:
- `thumbnailPath` - Returns first photo's thumbnail or null
- `photoCount` - Returns number of photos in collection

**Database Mapping**:
```sql
collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  createdAt TEXT NOT NULL,  -- ISO8601 string
  updatedAt TEXT NOT NULL   -- ISO8601 string
)
```

### 2. PhotoItem Model

**File**: `lib/models/photo_item.dart`

**Purpose**: Represents an individual photo within a collection.

**Properties**:
```dart
class PhotoItem {
  final String id;           // UUID identifier
  final String path;         // Full path to original image file
  final String? thumbnailPath; // Path to thumbnail (optional)
  final DateTime addedAt;    // When photo was added to collection
  final int order;          // Display order within collection
}
```

**Key Methods**:
- `toMap()` - Serializes to Map for database storage
- `fromMap(Map<String, dynamic> map)` - Deserializes from database
- `copyWith()` - Creates modified copy for reordering/updates

**Database Mapping**:
```sql
photos (
  id TEXT PRIMARY KEY,
  collectionId TEXT NOT NULL,  -- Foreign key to collections
  path TEXT NOT NULL,
  thumbnailPath TEXT,
  addedAt TEXT NOT NULL,       -- ISO8601 string
  photoOrder INTEGER NOT NULL, -- Maps to 'order' property
  FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
)
```

**Relationships**:
- Many-to-One with Collection (via collectionId foreign key)
- Cascade delete when parent collection is removed

### 3. AppSettings Model

**File**: `lib/models/app_settings.dart`

**Purpose**: Stores user preferences and application configuration.

**Enums**:
```dart
enum ThemeMode { system, light, dark }
```

**Properties**:
```dart
class AppSettings {
  // Presentation Settings
  final bool pinchToZoom;           // Enable zoom during presentation (default: false)
  final bool showPhotoCounter;      // Show "X of Y" counter (default: false)
  final bool autoAdvance;           // Enable slideshow mode (default: false)
  final int autoAdvanceInterval;    // Seconds between slides (default: 5)
  final bool autoLockEnabled;       // Enable auto-lock timer (default: false)
  final int autoLockMinutes;        // Minutes until auto-lock (default: 5)
  
  // Display Settings
  final ThemeMode themeMode;        // App theme (default: system)
  final bool transitionAnimations;  // Enable smooth transitions (default: true)
}
```

**Key Methods**:
- `toMap()` - Serializes to Map for SharedPreferences storage
- `fromMap(Map<String, dynamic> map)` - Deserializes with fallback defaults
- `copyWith()` - Creates modified copy for settings updates
- `_parseThemeMode(String? value)` - Static helper for enum parsing

**Storage**:
- Stored in SharedPreferences as JSON string
- Key: `'app_settings'`
- Graceful fallback to defaults if parsing fails

**Default Values**:
```dart
AppSettings() {
  pinchToZoom: false,
  showPhotoCounter: false,
  autoAdvance: false,
  autoAdvanceInterval: 5,
  autoLockEnabled: false,
  autoLockMinutes: 5,
  themeMode: ThemeMode.system,
  transitionAnimations: true,
}
```

## Data Relationships

### Collection ↔ PhotoItem Relationship

```
Collection (1) ←→ (Many) PhotoItem
- One collection can have multiple photos
- Photos are ordered by 'order' property
- Cascade delete: removing collection removes all photos
- Photos maintain order for consistent display
```

### Database Schema

```sql
-- Collections table
CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Photos table with foreign key relationship
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  collectionId TEXT NOT NULL,
  path TEXT NOT NULL,
  thumbnailPath TEXT,
  addedAt TEXT NOT NULL,
  photoOrder INTEGER NOT NULL,
  FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
);

-- Index for efficient collection queries
CREATE INDEX idx_photos_collection ON photos(collectionId);
```

## Serialization Patterns

### DateTime Handling
- All DateTime objects serialized as ISO8601 strings
- Consistent parsing with `DateTime.parse()`
- UTC timestamps for consistency

### Null Safety
- Optional properties use `?` nullable types
- `fromMap()` methods handle missing/null values gracefully
- Default values provided where appropriate

### Error Handling
- Graceful degradation for malformed data
- Fallback to default values when parsing fails
- Type-safe casting with null checks

## Usage Examples

### Creating a Collection
```dart
final collection = Collection(
  id: uuid.v4(),
  name: 'Vacation Photos',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  photos: selectedPhotos,
);
```

### Updating Settings
```dart
final newSettings = currentSettings.copyWith(
  pinchToZoom: true,
  autoAdvance: true,
  autoAdvanceInterval: 10,
);
```

### Reordering Photos
```dart
final reorderedPhotos = photos.asMap().entries.map((entry) {
  return entry.value.copyWith(order: entry.key);
}).toList();
```

## Validation Rules

### Collection
- `id`: Must be valid UUID
- `name`: Non-empty string, max 100 characters
- `createdAt`/`updatedAt`: Valid DateTime objects

### PhotoItem
- `id`: Must be valid UUID
- `path`: Must be valid file path
- `order`: Non-negative integer
- `addedAt`: Valid DateTime object

### AppSettings
- `autoAdvanceInterval`: 3, 5, 10, or 30 seconds
- `autoLockMinutes`: 1, 2, 5, 10, or 15 minutes
- All boolean flags: true/false only

This specification ensures consistent data handling across the application and provides clear guidelines for model usage and extension.