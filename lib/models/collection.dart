import 'photo_item.dart';

class Collection {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PhotoItem> photos;

  Collection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.photos = const [],
  });

  String? get thumbnailPath => photos.isNotEmpty ? photos.first.thumbnailPath ?? photos.first.path : null;

  int get photoCount => photos.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map, {List<PhotoItem>? photos}) {
    return Collection(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      photos: photos ?? [],
    );
  }

  Collection copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PhotoItem>? photos,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
    );
  }
}
