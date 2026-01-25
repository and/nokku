import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/photo_item.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final _uuid = const Uuid();

  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  Future<List<AssetPathEntity>> getAlbums() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );
    return albums;
  }

  Future<List<AssetEntity>> getPhotosFromAlbum(
    AssetPathEntity album, {
    int page = 0,
    int size = 100,
  }) async {
    final List<AssetEntity> photos = await album.getAssetListPaged(
      page: page,
      size: size,
    );
    return photos;
  }

  Future<PhotoItem?> assetToPhotoItem(AssetEntity asset, int order) async {
    final File? file = await asset.file;
    if (file == null) return null;

    final File? thumbFile = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)).then((data) async {
      if (data == null) return null;
      final tempDir = Directory.systemTemp;
      final thumbPath = '${tempDir.path}/thumb_${asset.id}.jpg';
      final thumbFile = File(thumbPath);
      await thumbFile.writeAsBytes(data);
      return thumbFile;
    });

    return PhotoItem(
      id: _uuid.v4(),
      path: file.path,
      thumbnailPath: thumbFile?.path,
      addedAt: DateTime.now(),
      order: order,
    );
  }

  Future<List<PhotoItem>> convertAssetsToPhotoItems(List<AssetEntity> assets) async {
    final List<PhotoItem> photoItems = [];

    for (int i = 0; i < assets.length; i++) {
      final photoItem = await assetToPhotoItem(assets[i], i);
      if (photoItem != null) {
        photoItems.add(photoItem);
      }
    }

    return photoItems;
  }
}
