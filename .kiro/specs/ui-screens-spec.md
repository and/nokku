# Safe Gallery - UI Screens Specification

## Overview

Safe Gallery implements platform-adaptive UI with separate Material Design (Android) and Cupertino (iOS) components. Each screen follows platform conventions while maintaining consistent functionality across platforms.

## UI Architecture Principles

### Platform Adaptation
- **Android**: Material Design 3 with Material widgets
- **iOS**: Cupertino design with iOS-style components
- **Shared Logic**: Common business logic with platform-specific UI
- **Responsive Design**: Adapts to different screen sizes and orientations

### Navigation Patterns
- **Android**: Standard Material navigation with app bars
- **iOS**: Cupertino navigation with navigation bars
- **Modal Presentations**: Platform-appropriate dialogs and sheets
- **Gesture Support**: Platform-specific gesture handling

## Screen Specifications

### 1. Collections Screen (Home)

**File**: `lib/screens/collections_screen.dart`

**Purpose**: Main screen displaying user's photo collections in a grid layout.

#### Platform Implementations

##### Android (_AndroidCollectionsScreen)
```dart
Scaffold(
  appBar: AppBar(title: 'Safe Gallery', actions: [Settings]),
  body: GridView | EmptyState,
  floatingActionButton: FloatingActionButton(+),
)
```

##### iOS (_IOSCollectionsScreen)
```dart
CupertinoPageScaffold(
  navigationBar: CupertinoNavigationBar(middle: 'Safe Gallery', trailing: Settings),
  child: CustomScrollView(SliverGrid) | EmptyState,
)
```

#### Key Features

**Collection Grid**:
- 2-column grid layout with 0.8 aspect ratio
- Collection cards show thumbnail, name, and photo count
- Tap to open presentation mode
- Long press for context menu (rename, add photos, delete)

**Empty State**:
- Centered icon and text when no collections exist
- Platform-appropriate create button
- Helpful guidance text

**Context Menu Actions**:
- **Rename**: Shows platform-appropriate text input dialog
- **Add Photos**: Navigates to PhotoPickerScreen
- **Delete**: Shows confirmation dialog with destructive styling

#### State Management
```dart
final provider = context.watch<AppProvider>();
final collections = provider.collections;
final isLoading = provider.isLoading;
```

#### Navigation
- Settings: `Navigator.push(SettingsScreen)`
- Create Collection: `Navigator.push(PhotoPickerScreen)`
- View Collection: `Navigator.push(PresentationScreen)`

### 2. Presentation Screen

**File**: `lib/screens/presentation_screen.dart`

**Purpose**: Full-screen photo viewer with secure presentation mode and device locking.

#### Core Features

**Immersive Display**:
- Full-screen black background
- Hidden system UI (status bar, navigation bar)
- Landscape and portrait support
- Keep screen on during presentation

**Photo Navigation**:
- PageView with infinite scroll (circular navigation)
- Swipe gestures for next/previous
- Tap zones (left/right thirds) for navigation
- Smooth transitions with 300ms animations

**Interactive Features**:
- Optional pinch-to-zoom with InteractiveViewer
- Optional photo counter overlay
- Auto-advance slideshow with configurable intervals
- Auto-lock timer with user interaction reset

**Security Integration**:
- Enters presentation mode on init
- Lifecycle observer for app state changes
- Device locking on background/pause events
- PopScope override to prevent back navigation

#### Widget Structure
```dart
PopScope(
  canPop: false,
  child: Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      child: Stack([
        PageView.builder(photos),
        PhotoCounterOverlay,
        TapZones(left, center, right),
        ExitButton(long press to lock),
      ]),
    ),
  ),
)
```

#### Lifecycle Management
```dart
class _PresentationScreenState extends State<PresentationScreen> 
    with WidgetsBindingObserver {
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockDevice();  // Critical security feature
    }
  }
}
```

#### Auto-Advance Implementation
```dart
Timer.periodic(Duration(seconds: interval), (timer) {
  if (mounted) {
    _goToNext();  // Automatic slideshow progression
  }
});
```

### 3. Photo Picker Screen

**File**: `lib/screens/photo_picker_screen.dart`

**Purpose**: Multi-select photo picker with album browsing and batch operations.

#### Platform Implementations

##### Android
```dart
Scaffold(
  appBar: AppBar(
    title: collectionName,
    actions: [Add (count) button],
  ),
  body: Column([
    DropdownButton(albums),
    Expanded(GridView(photos)),
  ]),
)
```

##### iOS
```dart
CupertinoPageScaffold(
  navigationBar: CupertinoNavigationBar(
    middle: collectionName,
    trailing: Add (count) button,
  ),
  child: Column([
    CupertinoButton(album picker),
    Expanded(GridView(photos)),
  ]),
)
```

#### Key Features

**Album Selection**:
- Dropdown (Android) or modal picker (iOS) for album selection
- Shows album name and photo count
- Loads photos on album change

**Photo Grid**:
- 3-column grid with square thumbnails
- Multi-select with visual selection indicators
- Tap to toggle selection
- Selected count in navigation bar

**Batch Operations**:
- Convert selected AssetEntity objects to PhotoItem models
- Generate thumbnails for selected photos
- Create new collection or add to existing collection
- Progress indication during processing

#### Selection State Management
```dart
final Set<AssetEntity> _selectedPhotos = {};
bool isSelected = _selectedPhotos.contains(photo);

// Toggle selection
setState(() {
  if (isSelected) {
    _selectedPhotos.remove(photo);
  } else {
    _selectedPhotos.add(photo);
  }
});
```

#### Photo Library Integration
```dart
// Permission handling
final hasPermission = await _photoService.requestPermission();

// Album loading
final albums = await _photoService.getAlbums();

// Photo loading with pagination
final photos = await _photoService.getPhotosFromAlbum(album, page: 0, size: 100);
```

### 4. Settings Screen

**File**: `lib/screens/settings_screen.dart`

**Purpose**: User preferences configuration with platform-appropriate controls.

#### Platform Implementations

##### Android
```dart
Scaffold(
  appBar: AppBar(title: 'Settings'),
  body: ListView([
    SectionHeaders,
    SwitchListTile(preferences),
    ListTile(dropdowns),
    DeviceAdminTile,
  ]),
)
```

##### iOS
```dart
CupertinoPageScaffold(
  navigationBar: CupertinoNavigationBar(middle: 'Settings'),
  child: ListView([
    SectionHeaders,
    CupertinoListSection.insetGrouped([
      CupertinoListTile(CupertinoSwitch),
      CupertinoListTile(pickers),
    ]),
  ]),
)
```

#### Settings Categories

**Presentation Settings**:
- Pinch to Zoom: Enable/disable zoom during presentation
- Show Photo Counter: Display "X of Y" overlay
- Auto-advance Slideshow: Enable with interval selection (3s, 5s, 10s, 30s)
- Auto-lock Timer: Enable with duration selection (1, 2, 5, 10, 15 minutes)

**Display Settings**:
- Theme: System/Light/Dark mode selection
- Transition Animations: Enable/disable smooth transitions

**Security Settings**:
- **Android**: Device Admin status and activation
- **iOS**: Guided Access instructions and setup guide

#### Platform-Specific Controls

##### Android Dropdowns
```dart
DropdownButton<int>(
  value: settings.autoAdvanceInterval,
  items: [3, 5, 10, 30].map((value) => 
    DropdownMenuItem(value: value, child: Text('${value}s'))
  ).toList(),
  onChanged: (value) => updateSettings(value),
)
```

##### iOS Pickers
```dart
CupertinoButton(
  child: Text('${settings.autoAdvanceInterval}s'),
  onPressed: () => showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoPicker(...),
  ),
)
```

#### Device Admin Integration (Android)
```dart
FutureBuilder<bool>(
  future: LockService().isDeviceAdminEnabled(),
  builder: (context, snapshot) {
    final isEnabled = snapshot.data ?? false;
    return ListTile(
      title: 'Device Admin',
      subtitle: isEnabled ? 'Enabled' : 'Tap to enable',
      trailing: isEnabled ? CheckIcon : WarningIcon,
      onTap: isEnabled ? null : () => LockService().requestDeviceAdmin(),
    );
  },
)
```

## Shared UI Components

### _CollectionCard Widget
```dart
class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: Column([
          Expanded(Image.file(thumbnail) | PlaceholderIcon),
          Padding(Text(name), Text(photoCount)),
        ]),
      ),
    );
  }
}
```

## Navigation Flow

```
CollectionsScreen (Home)
├── → SettingsScreen
├── → PhotoPickerScreen (Create Collection)
│   └── → Back to CollectionsScreen (with new collection)
├── → PresentationScreen (View Collection)
│   └── → Back to CollectionsScreen (after presentation)
└── → PhotoPickerScreen (Add Photos to Existing)
    └── → Back to CollectionsScreen (with updated collection)
```

## State Management Integration

### Provider Pattern Usage
```dart
// Watch for rebuilds
final provider = context.watch<AppProvider>();

// Read without rebuilds
context.read<AppProvider>().createCollection(name, photos);

// Select specific data
final collections = context.select<AppProvider, List<Collection>>(
  (provider) => provider.collections,
);
```

### Loading States
```dart
if (provider.isLoading) {
  return Platform.isIOS 
    ? CupertinoActivityIndicator()
    : CircularProgressIndicator();
}
```

## Error Handling

### User-Friendly Messages
- Permission denied: Clear instructions for enabling photo access
- Device admin required: Step-by-step activation guide
- Network/storage errors: Retry options with helpful context

### Platform-Appropriate Dialogs
```dart
// Android
showDialog(context: context, builder: (context) => AlertDialog(...));

// iOS  
showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(...));
```

## Accessibility

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper heading hierarchy
- Descriptive button labels

### Keyboard Navigation
- Tab order for focusable elements
- Enter/Space activation for buttons
- Escape key for modal dismissal

### Visual Accessibility
- High contrast support
- Scalable text sizes
- Color-blind friendly indicators

This UI specification ensures consistent, platform-appropriate user experiences while maintaining the core functionality across Android and iOS platforms.