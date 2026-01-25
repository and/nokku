enum MediaType { image, video }

class PhotoItem {
  final String id;
  final String path;
  final String? thumbnailPath;
  final DateTime addedAt;
  final int order;
  final MediaType mediaType;

  PhotoItem({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.addedAt,
    required this.order,
    this.mediaType = MediaType.image,
  });

  bool get isVideo => mediaType == MediaType.video;
  bool get isImage => mediaType == MediaType.image;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'thumbnailPath': thumbnailPath,
      'addedAt': addedAt.toIso8601String(),
      'order': order,
      'mediaType': mediaType.toString(),
    };
  }

  factory PhotoItem.fromMap(Map<String, dynamic> map) {
    return PhotoItem(
      id: map['id'] as String,
      path: map['path'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      order: map['order'] as int,
      mediaType: _parseMediaType(map['mediaType'] as String?),
    );
  }

  static MediaType _parseMediaType(String? value) {
    switch (value) {
      case 'MediaType.video':
        return MediaType.video;
      default:
        return MediaType.image;
    }
  }

  PhotoItem copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    DateTime? addedAt,
    int? order,
    MediaType? mediaType,
  }) {
    return PhotoItem(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      addedAt: addedAt ?? this.addedAt,
      order: order ?? this.order,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}
