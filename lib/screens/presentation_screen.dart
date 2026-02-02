import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/collection.dart';
import '../providers/app_provider.dart';
import '../services/lock_service.dart';
import '../screens/collections_screen.dart';
import '../widgets/video_player_widget.dart';

class PresentationScreen extends StatefulWidget {
  final Collection collection;
  final int initialIndex;
  final bool isTemporary; // New parameter to indicate if this is a temporary collection

  const PresentationScreen({
    super.key,
    required this.collection,
    this.initialIndex = 0,
    this.isTemporary = false, // Default to false for existing saved collections
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentIndex;
  Timer? _autoAdvanceTimer;
  final LockService _lockService = LockService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);

    // Enter presentation mode
    _lockService.enterPresentationMode();

    // Set up auto-advance if enabled
    _setupAutoAdvance();

    // Set up auto-lock timer if enabled
    _setupAutoLockTimer();

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Precache images for smoother transitions
    _precacheAdjacentImages();
  }

  void _precacheAdjacentImages() {
    // Precache current and adjacent images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final photos = widget.collection.photos;
      if (photos.isEmpty) return;

      // Precache current image
      _precacheImageIfNeeded(_currentIndex);

      // Precache next image
      final nextIndex = (_currentIndex + 1) % photos.length;
      _precacheImageIfNeeded(nextIndex);

      // Precache previous image
      final prevIndex = (_currentIndex - 1 + photos.length) % photos.length;
      _precacheImageIfNeeded(prevIndex);
    });
  }

  void _precacheImageIfNeeded(int index) {
    if (!mounted) return;

    final photo = widget.collection.photos[index];
    if (!photo.isVideo) {
      precacheImage(FileImage(File(photo.path)), context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _autoAdvanceTimer?.cancel();
    _lockService.exitPresentationMode();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Removed automatic locking to prevent lock loops
    // Only lock when explicitly requested by user actions
  }

  void _setupAutoAdvance() {
    final settings = context.read<AppProvider>().settings;
    if (settings.autoAdvance) {
      _startAutoAdvance(settings.autoAdvanceInterval);
    }
  }

  void _setupAutoLockTimer() {
    // Disabled auto-lock timer to prevent lock loops
    // final settings = context.read<AppProvider>().settings;
    // if (settings.autoLockEnabled) {
    //   _lockService.startAutoLockTimer(settings.autoLockMinutes);
    // }
  }

  void _startAutoAdvance(int seconds) {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (mounted) {
        _goToNext();
      }
    });
  }

  void _resetAutoLockTimer() {
    // Disabled auto-lock timer to prevent lock loops
    // final settings = context.read<AppProvider>().settings;
    // if (settings.autoLockEnabled) {
    //   _lockService.resetAutoLockTimer(settings.autoLockMinutes);
    // }
  }

  void _goToNext() {
    final nextIndex = (_currentIndex + 1) % widget.collection.photos.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevious() {
    final previousIndex = (_currentIndex - 1 + widget.collection.photos.length) %
                         widget.collection.photos.length;
    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _lockDevice() async {
    await _lockService.lockDevice();
  }

  Future<void> _handleExit() async {
    // Lock the device first for security
    await _lockDevice();
    
    // Show confirmation dialog after unlock
    if (widget.isTemporary) {
      // For temporary collections, ask if they want to save
      final action = await _showSaveDialog(context);
      if (action == 'save') {
        final collectionName = await _showNameDialog(context);
        if (collectionName != null && collectionName.isNotEmpty) {
          // Save the collection
          if (!mounted) return;
          await context.read<AppProvider>().createCollection(
            collectionName,
            widget.collection.photos,
          );
          if (mounted) {
            // Navigate back to Main screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CollectionsScreen()),
              (route) => false,
            );
            // Show success message after navigation
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Collection "$collectionName" saved!')),
                );
              }
            });
          }
        } else {
          // If no name provided, just exit without saving
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      } else if (action == 'discard') {
        // Navigate back to Main screen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CollectionsScreen()),
          (route) => false,
        );
      }
      // If action is null (cancelled), do nothing
    } else {
      // For saved collections, just show exit confirmation
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Exit Show', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to exit?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (shouldExit == true) {
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    }
  }

  void _removeCurrentPhoto() {
    if (widget.collection.photos.isEmpty) return;
    
    final settings = context.read<AppProvider>().settings;
    
    if (settings.confirmPhotoRemoval) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Remove Photo', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Remove this photo from the collection?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          _performPhotoRemoval();
        }
      });
    } else {
      // Remove directly without confirmation
      _performPhotoRemoval();
    }
  }

  void _performPhotoRemoval() {
    final photoToRemove = widget.collection.photos[_currentIndex];
    
    // Remove from collection
    widget.collection.photos.removeAt(_currentIndex);
    
    // If collection is empty, exit presentation
    if (widget.collection.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All photos removed from collection')),
      );
      Navigator.of(context).pop();
      return;
    }
    
    // Adjust current index if necessary
    if (_currentIndex >= widget.collection.photos.length) {
      _currentIndex = widget.collection.photos.length - 1;
    }
    
    // Update the page controller to show the correct photo
    setState(() {
      // Force rebuild with new collection
    });
    
    // Jump to the correct page
    _pageController.jumpToPage(_currentIndex);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed from collection'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // If this is a temporary collection, we don't need to update the database
    // If it's a saved collection, we should update it
    if (!widget.isTemporary) {
      // Update the saved collection in the database
      context.read<AppProvider>().removePhotoFromCollection(
        widget.collection.id,
        photoToRemove.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppProvider>().settings;

    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Handle back button the same as X button tap
        await _handleExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            _resetAutoLockTimer();
          },
          onHorizontalDragEnd: (details) {
            _resetAutoLockTimer();
          },
          child: Stack(
            children: [
              // Photo viewer with infinite loop
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % widget.collection.photos.length;
                  });
                  _resetAutoLockTimer();

                  // Precache adjacent images after page change
                  _precacheAdjacentImages();
                },
                itemCount: null, // Infinite scroll
                itemBuilder: (context, index) {
                  final photoIndex = index % widget.collection.photos.length;
                  final photo = widget.collection.photos[photoIndex];

                  return GestureDetector(
                    onVerticalDragEnd: settings.swipeToDelete ? (details) {
                      // Check if it's a swipe up gesture
                      if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
                        _removeCurrentPhoto();
                      }
                    } : null,
                    child: photo.isVideo 
                        ? VideoPlayerWidget(
                            videoPath: photo.path,
                            autoPlay: true,
                          )
                        : InteractiveViewer(
                            panEnabled: settings.pinchToZoom,
                            scaleEnabled: settings.pinchToZoom,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.file(
                                File(photo.path),
                                fit: BoxFit.contain,
                                gaplessPlayback: true, // Prevents flicker during transitions
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.white, size: 48),
                                  );
                                },
                              ),
                            ),
                          ),
                  );
                },
              ),

              // Photo counter overlay
              if (settings.showPhotoCounter)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.collection.photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // Tap zones for navigation (left/right thirds)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _goToPrevious();
                          _resetAutoLockTimer();
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                    Expanded(child: Container()), // Center third - no action
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _goToNext();
                          _resetAutoLockTimer();
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  ],
                ),
              ),

              // Exit button (tap to confirm exit, long press for immediate exit)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await _handleExit();
                  },
                  onLongPress: () async {
                    // Immediate exit with lock on long press
                    await _lockDevice();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showSaveDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Save Collection?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Would you like to save these photos as a collection?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Collection Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter collection name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
