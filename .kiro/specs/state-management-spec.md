# Safe Gallery - State Management Specification

## Overview

Safe Gallery uses the Provider pattern for state management, providing a clean separation between UI and business logic while maintaining reactive updates across the application.

## State Management Architecture

### Provider Pattern Implementation
```
MaterialApp/CupertinoApp
    ↓
ChangeNotifierProvider<AppProvider>
    ↓
Consumer Widgets (Screens)
    ↓
Business Logic (Services)
```

### Core Principles
- **Single Source of Truth**: AppProvider holds all application state
- **Reactive Updates**: UI automatically rebuilds when state changes
- **Immutable Data**: State updates create new objects rather than mutating existing ones
- **Async Operations**: All state changes are asynchronous with proper loading states

## AppProvider Implementation

### File Structure
**File**: `lib/providers/app_provider.dart`

### Class Definition
```dart
class AppProvider with ChangeNotifier {
  // Service dependencies
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  final _uuid = const Uuid();

  // Private state variables
  List<Collection> _collections = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  // Public getters
  List<Collection> get collections => _collections;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
}
```

## State Variables

### Collections State
```dart
List<Collection> _collections = [];
```
- **Purpose**: Holds all user photo collections
- **Updates**: Modified through CRUD operations
- **Persistence**: Automatically synced with SQLite database
- **Reactivity**: UI rebuilds when collections change

### Settings State
```dart
AppSettings _settings = AppSettings();
```
- **Purpose**: Holds user preferences and app configuration
- **Updates**: Modified through settings screen interactions
- **Persistence**: Automatically synced with SharedPreferences
- **Reactivity**: UI adapts to theme and behavior changes

### Loading State
```dart
bool _isLoading = false;
```
- **Purpose**: Indicates when async operations are in progress
- **Updates**: Set to true during operations, false when complete
- **UI Impact**: Shows loading indicators and disables interactions
- **Scope**: Global loading state for major operations

## State Initialization

### App Startup Flow
```dart
Future<void> initialize() async {
  _isLoading = true;
  notifyListeners();  // Show loading UI

  await Future.wait([
    _loadCollections(),  // Load from database
    _loadSettings(),     // Load from SharedPreferences
  ]);

  _isLoading = false;
  notifyListeners();   // Hide loading UI
}
```

### Parallel Loading Strategy
- Collections and settings load simultaneously
- Reduces app startup time
- Graceful error handling for each operation
- UI shows loading state during initialization

## Collection State Management

### Create Collection
```dart
Future<void> createCollection(String name, List<PhotoItem> photos) async {
  // Create new collection with UUID
  final collection = Collection(
    id: _uuid.v4(),
    name: name,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    photos: photos,
  );

  // Persist to database
  await _dbService.insertCollection(collection);
  
  // Reload state from database
  await _loadCollections();
  
  // Notify UI of changes
  notifyListeners();
}
```

### Update Collection Name
```dart
Future<void> updateCollectionName(String id, String newName) async {
  // Find existing collection
  final collection = _collections.firstWhere((c) => c.id == id);
  
  // Create updated copy (immutable)
  final updated = collection.copyWith(
    name: newName,
    updatedAt: DateTime.now(),
  );

  // Persist changes
  await _dbService.updateCollection(updated);
  await _loadCollections();
  notifyListeners();
}
```

### Add Photos to Collection
```dart
Future<void> addPhotosToCollection(String collectionId, List<PhotoItem> newPhotos) async {
  final collection = _collections.firstWhere((c) => c.id == collectionId);
  final currentPhotos = collection.photos;
  
  // Calculate order for new photos
  final startOrder = currentPhotos.isEmpty ? 0 : currentPhotos.last.order + 1;
  
  // Assign order to new photos
  final photosWithOrder = newPhotos.asMap().entries.map((entry) {
    return entry.value.copyWith(order: startOrder + entry.key);
  }).toList();

  // Combine photos
  final updatedPhotos = [...currentPhotos, ...photosWithOrder];
  
  // Update database
  await _dbService.updatePhotos(collectionId, updatedPhotos);
  
  // Update collection metadata
  final updated = collection.copyWith(
    photos: updatedPhotos,
    updatedAt: DateTime.now(),
  );
  await _dbService.updateCollection(updated);

  // Refresh state
  await _loadCollections();
  notifyListeners();
}
```

### Remove Photo from Collection
```dart
Future<void> removePhotoFromCollection(String collectionId, String photoId) async {
  final collection = _collections.firstWhere((c) => c.id == collectionId);
  
  // Filter out removed photo
  final updatedPhotos = collection.photos.where((p) => p.id != photoId).toList();

  // Reorder remaining photos
  for (int i = 0; i < updatedPhotos.length; i++) {
    updatedPhotos[i] = updatedPhotos[i].copyWith(order: i);
  }

  // Update database and state
  await _dbService.updatePhotos(collectionId, updatedPhotos);
  final updated = collection.copyWith(
    photos: updatedPhotos,
    updatedAt: DateTime.now(),
  );
  await _dbService.updateCollection(updated);

  await _loadCollections();
  notifyListeners();
}
```

### Reorder Photos
```dart
Future<void> reorderPhotos(String collectionId, List<PhotoItem> reorderedPhotos) async {
  final collection = _collections.firstWhere((c) => c.id == collectionId);

  // Update order indices
  for (int i = 0; i < reorderedPhotos.length; i++) {
    reorderedPhotos[i] = reorderedPhotos[i].copyWith(order: i);
  }

  // Persist reordered photos
  await _dbService.updatePhotos(collectionId, reorderedPhotos);
  
  final updated = collection.copyWith(
    photos: reorderedPhotos,
    updatedAt: DateTime.now(),
  );
  await _dbService.updateCollection(updated);

  await _loadCollections();
  notifyListeners();
}
```

### Delete Collection
```dart
Future<void> deleteCollection(String id) async {
  // Database handles cascade delete of photos
  await _dbService.deleteCollection(id);
  
  // Refresh collections list
  await _loadCollections();
  notifyListeners();
}
```

## Settings State Management

### Update Settings
```dart
Future<void> updateSettings(AppSettings newSettings) async {
  // Update in-memory state
  _settings = newSettings;
  
  // Persist to SharedPreferences
  await _settingsService.saveSettings(newSettings);
  
  // Notify UI of changes (theme, behavior updates)
  notifyListeners();
}
```

### Reset Settings
```dart
Future<void> resetSettings() async {
  // Reset to defaults
  _settings = AppSettings();
  
  // Clear persisted settings
  await _settingsService.resetSettings();
  
  // Update UI
  notifyListeners();
}
```

## UI Integration Patterns

### Provider Setup (main.dart)
```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const SafeGalleryApp(),
    ),
  );
}
```

### Watching State Changes
```dart
class CollectionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuilds when AppProvider state changes
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      body: provider.isLoading
          ? CircularProgressIndicator()
          : _buildCollectionGrid(provider.collections),
    );
  }
}
```

### Reading State Without Rebuilds
```dart
void _createCollection() {
  // Doesn't trigger rebuilds, just calls method
  context.read<AppProvider>().createCollection(name, photos);
}
```

### Selective State Watching
```dart
// Only rebuilds when collections change, not settings
final collections = context.select<AppProvider, List<Collection>>(
  (provider) => provider.collections,
);
```

## Error Handling Strategy

### Service Layer Errors
```dart
Future<void> createCollection(String name, List<PhotoItem> photos) async {
  try {
    // ... collection creation logic
  } catch (e) {
    // Log error for debugging
    print('Failed to create collection: $e');
    
    // Could emit error state or show user-friendly message
    // For now, graceful degradation
  }
}
```

### UI Error Display
```dart
// In UI widgets
if (provider.hasError) {
  return ErrorWidget(provider.errorMessage);
}
```

## Performance Optimizations

### Efficient Rebuilds
```dart
// Use Consumer for targeted rebuilds
Consumer<AppProvider>(
  builder: (context, provider, child) {
    return Text('${provider.collections.length} collections');
  },
)

// Use Selector for specific data
Selector<AppProvider, bool>(
  selector: (context, provider) => provider.isLoading,
  builder: (context, isLoading, child) {
    return isLoading ? LoadingWidget() : ContentWidget();
  },
)
```

### Memory Management
- Collections loaded lazily from database
- Photos loaded on-demand in UI
- Proper disposal of resources in services
- Weak references where appropriate

### Database Synchronization
- State always reflects database content
- Reload from database after mutations
- Consistent state across app lifecycle
- Handles concurrent access gracefully

## Testing State Management

### Unit Tests
```dart
test('should create collection and update state', () async {
  final provider = AppProvider();
  await provider.initialize();
  
  final initialCount = provider.collections.length;
  await provider.createCollection('Test', []);
  
  expect(provider.collections.length, initialCount + 1);
  expect(provider.collections.last.name, 'Test');
});
```

### Widget Tests
```dart
testWidgets('should show loading indicator', (tester) async {
  final provider = AppProvider();
  
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: CollectionsScreen()),
    ),
  );
  
  // Should show loading initially
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## State Persistence Strategy

### Database Persistence
- Collections and photos stored in SQLite
- Automatic foreign key relationships
- Indexed queries for performance
- Transaction support for consistency

### Settings Persistence
- User preferences in SharedPreferences
- JSON serialization for complex objects
- Graceful fallback to defaults
- Cross-platform compatibility

### State Restoration
- App state restored on startup
- Handles corrupted data gracefully
- Maintains consistency across app launches
- Supports data migration if needed

This state management specification ensures predictable, performant, and maintainable state handling throughout the Safe Gallery application.