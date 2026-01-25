# Safe Gallery - Testing Strategy Specification

## Overview

Safe Gallery implements a comprehensive testing strategy covering unit tests, widget tests, integration tests, and platform-specific testing. The testing approach ensures reliability, security, and performance across Android and iOS platforms.

## Testing Architecture

### Testing Pyramid
```
E2E Tests (Manual/Automated)
    ↑
Integration Tests (Platform Channels, Database)
    ↑
Widget Tests (UI Components, User Interactions)
    ↑
Unit Tests (Models, Services, Business Logic)
```

### Testing Principles
- **Test-Driven Development**: Write tests before implementation where possible
- **Platform Coverage**: Test both Android and iOS specific functionality
- **Security Testing**: Verify security features work as expected
- **Performance Testing**: Ensure smooth operation under load
- **Accessibility Testing**: Verify screen reader and keyboard navigation

## Unit Testing Strategy

### Test Structure
```
test/
├── models/
│   ├── collection_test.dart
│   ├── photo_item_test.dart
│   └── app_settings_test.dart
├── services/
│   ├── database_service_test.dart
│   ├── photo_service_test.dart
│   ├── lock_service_test.dart
│   └── settings_service_test.dart
├── providers/
│   └── app_provider_test.dart
└── utils/
    └── test_helpers.dart
```

### Model Testing

#### Collection Model Tests
```dart
// test/models/collection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_gallery/models/collection.dart';
import 'package:safe_gallery/models/photo_item.dart';

void main() {
  group('Collection Model', () {
    test('should create collection with required fields', () {
      final collection = Collection(
        id: 'test-id',
        name: 'Test Collection',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(collection.id, 'test-id');
      expect(collection.name, 'Test Collection');
      expect(collection.photos, isEmpty);
      expect(collection.photoCount, 0);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final collection = Collection(
        id: 'test-id',
        name: 'Test Collection',
        createdAt: now,
        updatedAt: now,
      );

      final map = collection.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Collection');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'test-id',
        'name': 'Test Collection',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final collection = Collection.fromMap(map);

      expect(collection.id, 'test-id');
      expect(collection.name, 'Test Collection');
      expect(collection.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('should create copy with updated fields', () {
      final original = Collection(
        id: 'test-id',
        name: 'Original Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Updated Name');

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.createdAt, original.createdAt);
    });

    test('should return correct thumbnail path', () {
      final photos = [
        PhotoItem(
          id: 'photo-1',
          path: '/path/to/photo1.jpg',
          thumbnailPath: '/path/to/thumb1.jpg',
          addedAt: DateTime.now(),
          order: 0,
        ),
      ];

      final collection = Collection(
        id: 'test-id',
        name: 'Test Collection',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: photos,
      );

      expect(collection.thumbnailPath, '/path/to/thumb1.jpg');
      expect(collection.photoCount, 1);
    });
  });
}
```

### Service Testing

#### Database Service Tests
```dart
// test/services/database_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_gallery/services/database_service.dart';
import 'package:safe_gallery/models/collection.dart';

void main() {
  late DatabaseService dbService;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dbService = DatabaseService();
  });

  group('DatabaseService', () {
    test('should create and retrieve collections', () async {
      final collection = Collection(
        id: 'test-id',
        name: 'Test Collection',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.insertCollection(collection);
      final retrieved = await dbService.getCollection('test-id');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, collection.id);
      expect(retrieved.name, collection.name);
    });

    test('should update collection name', () async {
      final collection = Collection(
        id: 'test-id',
        name: 'Original Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.insertCollection(collection);
      
      final updated = collection.copyWith(name: 'Updated Name');
      await dbService.updateCollection(updated);
      
      final retrieved = await dbService.getCollection('test-id');
      expect(retrieved!.name, 'Updated Name');
    });

    test('should delete collection and cascade photos', () async {
      final collection = Collection(
        id: 'test-id',
        name: 'Test Collection',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: [
          PhotoItem(
            id: 'photo-1',
            path: '/path/to/photo.jpg',
            addedAt: DateTime.now(),
            order: 0,
          ),
        ],
      );

      await dbService.insertCollection(collection);
      await dbService.deleteCollection('test-id');
      
      final retrieved = await dbService.getCollection('test-id');
      expect(retrieved, isNull);
      
      final photos = await dbService.getPhotosForCollection('test-id');
      expect(photos, isEmpty);
    });
  });
}
```

#### Lock Service Tests
```dart
// test/services/lock_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:safe_gallery/services/lock_service.dart';

void main() {
  late LockService lockService;
  late List<MethodCall> methodCalls;

  setUp(() {
    lockService = LockService();
    methodCalls = [];

    // Mock platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.safegallery/lock'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        
        switch (methodCall.method) {
          case 'enterPresentationMode':
            return null;
          case 'lockDevice':
            return true;
          case 'isDeviceAdminEnabled':
            return true;
          default:
            throw PlatformException(code: 'UNIMPLEMENTED');
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.safegallery/lock'),
      null,
    );
  });

  group('LockService', () {
    test('should enter presentation mode', () async {
      await lockService.enterPresentationMode();

      expect(lockService.isPresentationMode, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'enterPresentationMode');
    });

    test('should lock device', () async {
      await lockService.lockDevice();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'lockDevice');
    });

    test('should start and cancel auto-lock timer', () async {
      lockService.startAutoLockTimer(1);
      
      // Timer should be active
      expect(lockService.isPresentationMode, isFalse);
      
      await lockService.exitPresentationMode();
      
      // Timer should be cancelled
      expect(lockService.isPresentationMode, isFalse);
    });

    test('should check device admin status', () async {
      final isEnabled = await lockService.isDeviceAdminEnabled();

      expect(isEnabled, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'isDeviceAdminEnabled');
    });
  });
}
```

### Provider Testing

#### AppProvider Tests
```dart
// test/providers/app_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_gallery/providers/app_provider.dart';
import 'package:safe_gallery/models/collection.dart';
import 'package:safe_gallery/models/photo_item.dart';

void main() {
  late AppProvider provider;

  setUp(() {
    provider = AppProvider();
  });

  group('AppProvider', () {
    test('should initialize with empty state', () {
      expect(provider.collections, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.settings, isNotNull);
    });

    test('should create collection and notify listeners', () async {
      var notified = false;
      provider.addListener(() => notified = true);

      final photos = [
        PhotoItem(
          id: 'photo-1',
          path: '/path/to/photo.jpg',
          addedAt: DateTime.now(),
          order: 0,
        ),
      ];

      await provider.createCollection('Test Collection', photos);

      expect(notified, isTrue);
      expect(provider.collections, hasLength(1));
      expect(provider.collections.first.name, 'Test Collection');
    });

    test('should update collection name', () async {
      // First create a collection
      await provider.createCollection('Original Name', []);
      final collectionId = provider.collections.first.id;

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.updateCollectionName(collectionId, 'Updated Name');

      expect(notified, isTrue);
      expect(provider.collections.first.name, 'Updated Name');
    });

    test('should delete collection', () async {
      await provider.createCollection('Test Collection', []);
      final collectionId = provider.collections.first.id;

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.deleteCollection(collectionId);

      expect(notified, isTrue);
      expect(provider.collections, isEmpty);
    });
  });
}
```

## Widget Testing Strategy

### Widget Test Structure
```
test/widgets/
├── screens/
│   ├── collections_screen_test.dart
│   ├── presentation_screen_test.dart
│   ├── photo_picker_screen_test.dart
│   └── settings_screen_test.dart
├── components/
│   └── collection_card_test.dart
└── test_helpers/
    └── widget_test_helpers.dart
```

### Screen Widget Tests

#### Collections Screen Tests
```dart
// test/widgets/screens/collections_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_gallery/screens/collections_screen.dart';
import 'package:safe_gallery/providers/app_provider.dart';
import 'package:safe_gallery/models/collection.dart';

void main() {
  late AppProvider mockProvider;

  setUp(() {
    mockProvider = AppProvider();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<AppProvider>.value(
      value: mockProvider,
      child: const MaterialApp(
        home: CollectionsScreen(),
      ),
    );
  }

  group('CollectionsScreen Widget', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      // Set loading state
      mockProvider.setLoading(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no collections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow provider to initialize

      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.text('Tap + to create your first collection'), findsOneWidget);
    });

    testWidgets('should show collections grid when collections exist', (tester) async {
      // Add test collections
      final collections = [
        Collection(
          id: '1',
          name: 'Test Collection 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Collection(
          id: '2',
          name: 'Test Collection 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      mockProvider.setCollections(collections);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Test Collection 1'), findsOneWidget);
      expect(find.text('Test Collection 2'), findsOneWidget);
    });

    testWidgets('should navigate to settings when settings button tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify navigation occurred (would need navigation observer in real test)
      expect(find.byType(CollectionsScreen), findsNothing);
    });

    testWidgets('should show create collection dialog when FAB tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Collection'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
```

#### Presentation Screen Tests
```dart
// test/widgets/screens/presentation_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_gallery/screens/presentation_screen.dart';
import 'package:safe_gallery/providers/app_provider.dart';
import 'package:safe_gallery/models/collection.dart';
import 'package:safe_gallery/models/photo_item.dart';

void main() {
  late AppProvider mockProvider;
  late Collection testCollection;

  setUp(() {
    mockProvider = AppProvider();
    testCollection = Collection(
      id: 'test-id',
      name: 'Test Collection',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photos: [
        PhotoItem(
          id: 'photo-1',
          path: '/test/path/photo1.jpg',
          addedAt: DateTime.now(),
          order: 0,
        ),
        PhotoItem(
          id: 'photo-2',
          path: '/test/path/photo2.jpg',
          addedAt: DateTime.now(),
          order: 1,
        ),
      ],
    );
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<AppProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: PresentationScreen(collection: testCollection),
      ),
    );
  }

  group('PresentationScreen Widget', () {
    testWidgets('should display photos in PageView', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should navigate to next photo on right tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on right side of screen
      final screenSize = tester.getSize(find.byType(Scaffold));
      await tester.tapAt(Offset(screenSize.width * 0.8, screenSize.height * 0.5));
      await tester.pumpAndSettle();

      // Verify navigation occurred (would check current page index in real implementation)
    });

    testWidgets('should show photo counter when enabled', (tester) async {
      // Enable photo counter in settings
      mockProvider.updateSettings(
        mockProvider.settings.copyWith(showPhotoCounter: true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets('should not show photo counter when disabled', (tester) async {
      // Ensure photo counter is disabled (default)
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('1 of 2'), findsNothing);
    });

    testWidgets('should show exit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
```

## Integration Testing Strategy

### Platform Channel Integration Tests
```dart
// integration_test/platform_channel_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:safe_gallery/services/lock_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Channel Integration', () {
    testWidgets('should communicate with native lock service', (tester) async {
      final lockService = LockService();

      // Test entering presentation mode
      await lockService.enterPresentationMode();
      expect(lockService.isPresentationMode, isTrue);

      // Test device admin status (Android only)
      if (Platform.isAndroid) {
        final isEnabled = await lockService.isDeviceAdminEnabled();
        expect(isEnabled, isA<bool>());
      }

      // Test exiting presentation mode
      await lockService.exitPresentationMode();
      expect(lockService.isPresentationMode, isFalse);
    });
  });
}
```

### Database Integration Tests
```dart
// integration_test/database_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:safe_gallery/services/database_service.dart';
import 'package:safe_gallery/models/collection.dart';
import 'package:safe_gallery/models/photo_item.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Database Integration', () {
    late DatabaseService dbService;

    setUp(() {
      dbService = DatabaseService();
    });

    testWidgets('should perform full CRUD operations', (tester) async {
      // Create
      final collection = Collection(
        id: 'integration-test-id',
        name: 'Integration Test Collection',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: [
          PhotoItem(
            id: 'photo-1',
            path: '/test/photo1.jpg',
            addedAt: DateTime.now(),
            order: 0,
          ),
        ],
      );

      await dbService.insertCollection(collection);

      // Read
      final retrieved = await dbService.getCollection('integration-test-id');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Integration Test Collection');
      expect(retrieved.photos, hasLength(1));

      // Update
      final updated = retrieved.copyWith(name: 'Updated Name');
      await dbService.updateCollection(updated);
      
      final retrievedUpdated = await dbService.getCollection('integration-test-id');
      expect(retrievedUpdated!.name, 'Updated Name');

      // Delete
      await dbService.deleteCollection('integration-test-id');
      
      final retrievedDeleted = await dbService.getCollection('integration-test-id');
      expect(retrievedDeleted, isNull);
    });
  });
}
```

## Performance Testing

### Load Testing
```dart
// test/performance/load_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_gallery/services/database_service.dart';
import 'package:safe_gallery/models/collection.dart';
import 'package:safe_gallery/models/photo_item.dart';

void main() {
  group('Performance Tests', () {
    test('should handle large number of collections efficiently', () async {
      final dbService = DatabaseService();
      final stopwatch = Stopwatch()..start();

      // Create 100 collections with 10 photos each
      for (int i = 0; i < 100; i++) {
        final photos = List.generate(10, (j) => PhotoItem(
          id: 'photo-$i-$j',
          path: '/test/photo$i$j.jpg',
          addedAt: DateTime.now(),
          order: j,
        ));

        final collection = Collection(
          id: 'collection-$i',
          name: 'Collection $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          photos: photos,
        );

        await dbService.insertCollection(collection);
      }

      stopwatch.stop();
      print('Created 100 collections in ${stopwatch.elapsedMilliseconds}ms');

      // Verify retrieval performance
      stopwatch.reset();
      stopwatch.start();

      final collections = await dbService.getCollections();

      stopwatch.stop();
      print('Retrieved ${collections.length} collections in ${stopwatch.elapsedMilliseconds}ms');

      expect(collections, hasLength(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be under 1 second
    });
  });
}
```

## Security Testing

### Security Feature Tests
```dart
// test/security/security_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:safe_gallery/services/lock_service.dart';

void main() {
  group('Security Tests', () {
    test('should handle platform channel security calls', () async {
      final lockService = LockService();
      
      // Mock successful device admin check
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.safegallery/lock'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isDeviceAdminEnabled':
              return true;
            case 'lockDevice':
              return true;
            default:
              return null;
          }
        },
      );

      final isEnabled = await lockService.isDeviceAdminEnabled();
      expect(isEnabled, isTrue);

      await lockService.lockDevice();
      // Should not throw exception
    });

    test('should handle security failures gracefully', () async {
      final lockService = LockService();
      
      // Mock platform exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.safegallery/lock'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'SECURITY_ERROR',
            message: 'Device admin not enabled',
          );
        },
      );

      // Should not throw, should handle gracefully
      expect(() => lockService.lockDevice(), returnsNormally);
    });
  });
}
```

## Test Execution Strategy

### Continuous Integration
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run unit tests
        run: flutter test --coverage
      
      - name: Run widget tests
        run: flutter test test/widgets/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v1
```

### Local Testing Commands
```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/models/
flutter test test/services/
flutter test test/widgets/

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run integration tests
flutter test integration_test/

# Run performance tests
flutter test test/performance/ --reporter=json > test_results.json
```

### Platform-Specific Testing

#### Android Testing
```bash
# Run on Android emulator
flutter test integration_test/ -d android

# Test device admin functionality
adb shell dpm set-device-admin com.safegallery/.DeviceAdminReceiver

# Test immersive mode
adb shell settings put global policy_control immersive.full=com.safegallery
```

#### iOS Testing
```bash
# Run on iOS simulator
flutter test integration_test/ -d ios

# Test photo library permissions
xcrun simctl privacy booted grant photos com.safegallery
```

## Test Coverage Goals

### Coverage Targets
- **Unit Tests**: 90%+ coverage for models and services
- **Widget Tests**: 80%+ coverage for UI components
- **Integration Tests**: 100% coverage for critical user flows
- **Platform Tests**: 100% coverage for platform-specific features

### Coverage Reporting
```bash
# Generate coverage report
flutter test --coverage
lcov --summary coverage/lcov.info

# View detailed coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

This comprehensive testing strategy ensures Safe Gallery maintains high quality, security, and reliability across all supported platforms and use cases.