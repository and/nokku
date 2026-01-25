import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Initializing video: ${widget.videoPath}');
      }
      
      // Check if file exists
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found at: ${widget.videoPath}';
        });
        return;
      }

      // Check file size
      final fileSize = await file.length();
      if (kDebugMode) {
        print('DEBUG: Video file size: $fileSize bytes');
      }
      
      if (fileSize == 0) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file is empty';
        });
        return;
      }

      // Check file permissions by trying to read first few bytes
      try {
        final bytes = await file.openRead(0, 1024).first;
        if (kDebugMode) {
          print('DEBUG: Successfully read ${bytes.length} bytes from video file');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Cannot read video file: $e');
        }
        setState(() {
          _hasError = true;
          _errorMessage = 'Cannot access video file. This may be due to permission restrictions.\n\nFile: ${widget.videoPath}\nError: $e';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      
      // Add listener for errors
      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          if (kDebugMode) {
            print('DEBUG: Video player error: ${_controller!.value.errorDescription}');
          }
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video playback error: ${_controller!.value.errorDescription}';
            });
          }
        }
      });
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        if (kDebugMode) {
          print('DEBUG: Video initialized successfully. Duration: ${_controller!.value.duration}');
        }
        
        if (widget.autoPlay) {
          _controller!.play();
        }
        
        // Auto-hide controls after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('ERROR: PlatformException during video initialization: ${e.code} - ${e.message}');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Platform error: ${e.message}\nCode: ${e.code}\n\nThis may be due to:\n• Unsupported video format\n• File permission issues\n• Corrupted video file\n\nFile: ${widget.videoPath}';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: General error during video initialization: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e\n\nFile: ${widget.videoPath}\n\nTry:\n• Different video format (MP4 recommended)\n• Check file permissions\n• Ensure file is not corrupted';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Video error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading state
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          
          // Controls overlay
          if (_showControls)
            Container(
              color: Colors.black26,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Play/Pause button
                  Center(
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Progress bar and time
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress bar
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Time display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller!.value.position),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(_controller!.value.duration),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}