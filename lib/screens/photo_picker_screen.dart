import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/app_provider.dart';
import '../services/photo_service.dart';
import '../models/collection.dart';
import 'presentation_screen.dart';

class PhotoPickerScreen extends StatefulWidget {
  final String? collectionId;
  final String collectionName;
  final bool isQuickPresent; // New parameter to indicate Quick Present mode

  const PhotoPickerScreen({
    super.key,
    this.collectionId,
    required this.collectionName,
    this.isQuickPresent = false, // Default to false for normal collections
  });

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  final PhotoService _photoService = PhotoService();
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _photos = [];
  final Set<AssetEntity> _selectedPhotos = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final hasPermission = await _photoService.requestPermission();
    if (!hasPermission) {
      _showPermissionError();
      return;
    }

    final albums = await _photoService.getAlbums();
    setState(() {
      _albums = albums;
      if (albums.isNotEmpty) {
        _selectedAlbum = albums.first;
        _loadPhotos();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadPhotos() async {
    if (_selectedAlbum == null) return;

    setState(() => _isLoading = true);
    final photos = await _photoService.getPhotosFromAlbum(_selectedAlbum!);
    setState(() {
      _photos = photos;
      _isLoading = false;
    });
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please grant photo library access to select photos.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelection() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one photo')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final photoItems = await _photoService.convertAssetsToPhotoItems(_selectedPhotos.toList());

      if (widget.collectionId == null) {
        // Create new collection
        await context.read<AppProvider>().createCollection(
          widget.collectionName,
          photoItems,
        );
      } else {
        // Add to existing collection
        await context.read<AppProvider>().addPhotosToCollection(
          widget.collectionId!,
          photoItems,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${photoItems.length} photo${photoItems.length != 1 ? 's' : ''}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _quickPresent() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one photo')),
      );
      return;
    }

    try {
      // Convert selected photos to PhotoItems
      final photoItems = await _photoService.convertAssetsToPhotoItems(_selectedPhotos.toList());
      
      // Create a temporary collection
      final tempCollection = Collection(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Quick Show',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: photoItems,
      );

      // Navigate to presentation screen with temporary flag
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PresentationScreen(
              collection: tempCollection,
              isTemporary: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildIOSUI() : _buildAndroidUI();
  }

  Widget _buildAndroidUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionName),
        actions: [
          if (_selectedPhotos.isNotEmpty) ...[
            TextButton(
              onPressed: _quickPresent,
              child: Text('Show (${_selectedPhotos.length})'),
            ),
            if (!widget.isQuickPresent) // Only show Save button if not in Quick Present mode
              TextButton(
                onPressed: _isSaving ? null : _saveSelection,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Save (${_selectedPhotos.length})'),
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_albums.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<AssetPathEntity>(
                value: _selectedAlbum,
                isExpanded: true,
                items: _albums.map((album) {
                  return DropdownMenuItem(
                    value: album,
                    child: FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text('${album.name} ($count)');
                      },
                    ),
                  );
                }).toList(),
                onChanged: (album) {
                  setState(() {
                    _selectedAlbum = album;
                    _loadPhotos();
                  });
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPhotoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSUI() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.collectionName),
        trailing: _selectedPhotos.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _quickPresent,
                    child: Text('Show (${_selectedPhotos.length})'),
                  ),
                  if (!widget.isQuickPresent) // Only show Save button if not in Quick Present mode
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isSaving ? null : _saveSelection,
                      child: _isSaving
                          ? const CupertinoActivityIndicator()
                          : Text('Save (${_selectedPhotos.length})'),
                    ),
                ],
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_albums.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.systemGrey5,
                  onPressed: () => _showAlbumPicker(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedAlbum?.name ?? 'Select Album',
                        style: const TextStyle(color: CupertinoColors.black),
                      ),
                      const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.black),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildPhotoGrid(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlbumPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Album', style: TextStyle(fontWeight: FontWeight.bold)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  return CupertinoButton(
                    onPressed: () {
                      setState(() {
                        _selectedAlbum = album;
                        _loadPhotos();
                      });
                      Navigator.pop(context);
                    },
                    child: FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text('${album.name} ($count)');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    if (_photos.isEmpty) {
      return const Center(
        child: Text('No photos in this album'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final isSelected = _selectedPhotos.contains(photo);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedPhotos.remove(photo);
              } else {
                _selectedPhotos.add(photo);
              }
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              AssetEntityImage(
                photo,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(200),
                fit: BoxFit.cover,
              ),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Platform.isIOS ? CupertinoColors.activeBlue : Colors.blue,
                      width: 3,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Platform.isIOS ? CupertinoColors.activeBlue : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Platform.isIOS ? CupertinoIcons.check_mark : Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
