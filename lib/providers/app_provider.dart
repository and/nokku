import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/collection.dart';
import '../models/photo_item.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  final _uuid = const Uuid();

  List<Collection> _collections = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  List<Collection> get collections => _collections;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadCollections(),
      _loadSettings(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCollections() async {
    _collections = await _dbService.getCollections();
  }

  Future<void> _loadSettings() async {
    _settings = await _settingsService.loadSettings();
  }

  // Collection operations
  Future<void> createCollection(String name, List<PhotoItem> photos) async {
    final collection = Collection(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photos: photos,
    );

    await _dbService.insertCollection(collection);
    await _loadCollections();
    notifyListeners();
  }

  Future<void> updateCollectionName(String id, String newName) async {
    final collection = _collections.firstWhere((c) => c.id == id);
    final updated = collection.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );

    await _dbService.updateCollection(updated);
    await _loadCollections();
    notifyListeners();
  }

  Future<void> addPhotosToCollection(String collectionId, List<PhotoItem> newPhotos) async {
    final collection = _collections.firstWhere((c) => c.id == collectionId);
    final currentPhotos = collection.photos;
    final startOrder = currentPhotos.isEmpty ? 0 : currentPhotos.last.order + 1;

    final photosWithOrder = newPhotos.asMap().entries.map((entry) {
      return entry.value.copyWith(order: startOrder + entry.key);
    }).toList();

    final updatedPhotos = [...currentPhotos, ...photosWithOrder];
    await _dbService.updatePhotos(collectionId, updatedPhotos);

    final updated = collection.copyWith(
      photos: updatedPhotos,
      updatedAt: DateTime.now(),
    );
    await _dbService.updateCollection(updated);

    await _loadCollections();
    notifyListeners();
  }

  Future<void> removePhotoFromCollection(String collectionId, String photoId) async {
    final collection = _collections.firstWhere((c) => c.id == collectionId);
    final updatedPhotos = collection.photos.where((p) => p.id != photoId).toList();

    // Reorder photos
    for (int i = 0; i < updatedPhotos.length; i++) {
      updatedPhotos[i] = updatedPhotos[i].copyWith(order: i);
    }

    await _dbService.updatePhotos(collectionId, updatedPhotos);

    final updated = collection.copyWith(
      photos: updatedPhotos,
      updatedAt: DateTime.now(),
    );
    await _dbService.updateCollection(updated);

    await _loadCollections();
    notifyListeners();
  }

  Future<void> reorderPhotos(String collectionId, List<PhotoItem> reorderedPhotos) async {
    final collection = _collections.firstWhere((c) => c.id == collectionId);

    // Update order
    for (int i = 0; i < reorderedPhotos.length; i++) {
      reorderedPhotos[i] = reorderedPhotos[i].copyWith(order: i);
    }

    await _dbService.updatePhotos(collectionId, reorderedPhotos);

    final updated = collection.copyWith(
      photos: reorderedPhotos,
      updatedAt: DateTime.now(),
    );
    await _dbService.updateCollection(updated);

    await _loadCollections();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    await _dbService.deleteCollection(id);
    await _loadCollections();
    notifyListeners();
  }

  // Settings operations
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    _settings = AppSettings();
    await _settingsService.resetSettings();
    notifyListeners();
  }
}
