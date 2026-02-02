import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/collection.dart';
import '../models/photo_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'safe_gallery.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        collectionId TEXT NOT NULL,
        path TEXT NOT NULL,
        thumbnailPath TEXT,
        addedAt TEXT NOT NULL,
        photoOrder INTEGER NOT NULL,
        mediaType TEXT DEFAULT 'MediaType.image',
        FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_photos_collection ON photos(collectionId)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add mediaType column to existing photos table
      await db.execute('''
        ALTER TABLE photos ADD COLUMN mediaType TEXT DEFAULT 'MediaType.image'
      ''');

      // Update existing records to detect videos by file extension
      final photos = await db.query('photos');
      for (final photo in photos) {
        final path = photo['path'] as String;
        final extension = path.toLowerCase().split('.').last;
        const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', '3gp', 'webm', 'm4v', '3gpp', 'ts', 'mts'];

        if (videoExtensions.contains(extension)) {
          await db.update(
            'photos',
            {'mediaType': 'MediaType.video'},
            where: 'id = ?',
            whereArgs: [photo['id']],
          );
        }
      }
    }
  }

  // Collection operations
  Future<List<Collection>> getCollections() async {
    final db = await database;
    final List<Map<String, dynamic>> collectionMaps = await db.query(
      'collections',
      orderBy: 'updatedAt DESC',
    );

    final collections = <Collection>[];
    for (final map in collectionMaps) {
      final photos = await getPhotosForCollection(map['id'] as String);
      collections.add(Collection.fromMap(map, photos: photos));
    }

    return collections;
  }

  Future<Collection?> getCollection(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final photos = await getPhotosForCollection(id);
    return Collection.fromMap(maps.first, photos: photos);
  }

  Future<void> insertCollection(Collection collection) async {
    final db = await database;
    await db.insert('collections', collection.toMap());

    for (final photo in collection.photos) {
      await insertPhoto(collection.id, photo);
    }
  }

  Future<void> updateCollection(Collection collection) async {
    final db = await database;
    await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<void> deleteCollection(String id) async {
    final db = await database;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
    await db.delete('photos', where: 'collectionId = ?', whereArgs: [id]);
  }

  // Photo operations
  Future<List<PhotoItem>> getPhotosForCollection(String collectionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'collectionId = ?',
      whereArgs: [collectionId],
      orderBy: 'photoOrder ASC',
    );

    return maps.map((map) {
      return PhotoItem.fromMap({
        'id': map['id'],
        'path': map['path'],
        'thumbnailPath': map['thumbnailPath'],
        'addedAt': map['addedAt'],
        'order': map['photoOrder'],
        'mediaType': map['mediaType'],
      });
    }).toList();
  }

  Future<void> insertPhoto(String collectionId, PhotoItem photo) async {
    final db = await database;
    await db.insert('photos', {
      'id': photo.id,
      'collectionId': collectionId,
      'path': photo.path,
      'thumbnailPath': photo.thumbnailPath,
      'addedAt': photo.addedAt.toIso8601String(),
      'photoOrder': photo.order,
      'mediaType': photo.mediaType.toString(),
    });
  }

  Future<void> updatePhotos(String collectionId, List<PhotoItem> photos) async {
    final db = await database;
    await db.delete('photos', where: 'collectionId = ?', whereArgs: [collectionId]);

    for (final photo in photos) {
      await insertPhoto(collectionId, photo);
    }
  }

  Future<void> deletePhoto(String photoId) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }
}
