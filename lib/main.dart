import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/collections_screen.dart';
import 'screens/presentation_screen.dart';
import 'models/collection.dart';
import 'models/photo_item.dart';
import 'models/app_settings.dart';
import 'services/intent_service.dart';
import 'services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const SafeGalleryApp(),
    ),
  );
}

class SafeGalleryApp extends StatefulWidget {
  const SafeGalleryApp({super.key});

  @override
  State<SafeGalleryApp> createState() => _SafeGalleryAppState();
}

class _SafeGalleryAppState extends State<SafeGalleryApp> {
  List<String> _sharedFiles = [];
  bool _hasSharedContent = false;

  @override
  void initState() {
    super.initState();
    _handleSharedIntents();
    _checkForUpdates();
  }

  void _checkForUpdates() async {
    // Check for app updates after a short delay to avoid blocking startup
    await Future.delayed(const Duration(seconds: 2));
    await UpdateService().checkForUpdate();
  }

  void _handleSharedIntents() async {
    if (Platform.isAndroid) {
      // Check if app was launched with shared content
      final hasShared = await IntentService.hasSharedContent();
      if (hasShared) {
        // Check and request storage permissions if needed
        final hasPermission = await IntentService.hasStoragePermission();
        if (!hasPermission) {
          await IntentService.requestStoragePermission();
          // Wait a bit for permission dialog to complete
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        final sharedFiles = await IntentService.getSharedFiles();
        if (sharedFiles.isNotEmpty) {
          setState(() {
            _sharedFiles = sharedFiles;
            _hasSharedContent = true;
          });
        }
      }
    }
  }

  MediaType _getMediaType(String path) {
    final extension = path.toLowerCase().split('.').last;
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', '3gp', 'webm', 'm4v'];
    return videoExtensions.contains(extension) ? MediaType.video : MediaType.image;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    // Determine brightness based on theme mode
    Brightness brightness;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        brightness = Brightness.light;
        break;
      case AppThemeMode.dark:
        brightness = Brightness.dark;
        break;
      default:
        brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    // Determine the home screen based on whether we have shared content
    Widget homeScreen;
    if (_hasSharedContent && _sharedFiles.isNotEmpty) {
      // Create temporary collection from shared files
      final photoItems = _sharedFiles
          .asMap()
          .entries
          .map((entry) {
            final path = entry.value;
            final mediaType = _getMediaType(path);
            return PhotoItem(
              id: 'shared_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
              path: path,
              addedAt: DateTime.now(),
              order: entry.key,
              mediaType: mediaType,
            );
          })
          .toList();

      final tempCollection = Collection(
        id: 'shared_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Shared Photos',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: photoItems,
      );

      homeScreen = PresentationScreen(
        collection: tempCollection,
        isTemporary: true,
      );

      // Clear shared content after processing
      IntentService.clearSharedContent();
    } else {
      homeScreen = const CollectionsScreen();
    }

    if (Platform.isIOS) {
      return CupertinoApp(
        title: 'Nokku temp gallery',
        theme: CupertinoThemeData(
          brightness: brightness,
          primaryColor: CupertinoColors.activeBlue,
        ),
        home: homeScreen,
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        title: 'Nokku temp gallery',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: homeScreen,
        debugShowCheckedModeBanner: false,
      );
    }
  }
}
