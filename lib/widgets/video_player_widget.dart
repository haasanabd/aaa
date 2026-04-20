import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File file;
  const VideoPlayerWidget({super.key, required this.file});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _controller = VideoPlayerController.file(widget.file);
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ في تحميل الفيديو: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    // التخلص من الموارد فوراً عند الخروج من الشاشة لضمان عدم تهنيج التطبيق
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        // واجهة تحكم بسيطة وفعالة
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
        // شريط تقدم الفيديو (اختياري)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }
}
