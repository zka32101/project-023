/// Video preview and playback screen with sharing capabilities

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/video_storage_service.dart';
import 'package:tsukuani/widgets/social_share_dialog.dart';

/// Screen for previewing and interacting with a saved video
class VideoPreviewScreen extends StatefulWidget {
  /// The video to preview
  final SavedVideo video;

  /// Callback when video is deleted
  final VoidCallback? onVideoDeleted;

  /// Callback when video is shared
  final VoidCallback? onVideoShared;

  const VideoPreviewScreen({
    Key? key,
    required this.video,
    this.onVideoDeleted,
    this.onVideoShared,
  }) : super(key: key);

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isLoadingMetadata = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final videoFile = File(widget.video.filePath);

    _controller = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
      }).catchError((error) {
        setState(() {
          _errorMessage = 'Failed to load video: $error';
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text(
          'Are you sure you want to delete this video? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final storageService = VideoStorageService.instance;
              final deleted = await storageService.deleteVideo(
                widget.video.id,
                widget.video.projectId,
              );

              if (deleted && mounted) {
                widget.onVideoDeleted?.call();
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete video')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => SocialShareDialog(
        video: widget.video,
        onShare: () {
          widget.onVideoShared?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video shared successfully')),
            );
          }
        },
      ),
    );
  }

  void _downloadVideo() {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Preview'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
            ],
          ),
        ),
      );
    }

    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildVideoControls(),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit,
                    color: Colors.white),
                onPressed: _toggleFullScreen,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.getDisplayName()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
                onTap: _downloadVideo,
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: _deleteVideo,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video player
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _controller.value.isInitialized
                    ? Stack(
                        children: [
                          VideoPlayer(_controller),
                          Center(
                            child: GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 8),
            // Video controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildVideoControls(),
            ),
            const SizedBox(height: 16),
            // Metadata
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMetadataSection(),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActionButtons(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Column(
      children: [
        if (_controller.value.isInitialized)
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFF6366F1),
              bufferedColor: Color(0xFF8B5CF6),
              backgroundColor: Colors.grey,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
            ),
            if (_controller.value.isInitialized)
              Text(
                _buildTimerString(
                  _controller.value.position,
                  _controller.value.duration,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _toggleFullScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    final metadata = widget.video.metadata;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Resolution', metadata.getResolutionString()),
            _buildMetadataRow('File Size', metadata.getFileSizeString()),
            _buildMetadataRow('Format', metadata.format.toUpperCase()),
            _buildMetadataRow('Frame Rate', '${metadata.fps} fps'),
            _buildMetadataRow(
              'Duration',
              '${metadata.durationSeconds.toStringAsFixed(1)}s',
            ),
            _buildMetadataRow(
              'Created',
              _formatDateTime(metadata.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showShareDialog,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _downloadVideo,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _deleteVideo,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  String _buildTimerString(Duration position, Duration duration) {
    final positionInSeconds = position.inSeconds;
    final durationInSeconds = duration.inSeconds;

    final positionMinutes = positionInSeconds ~/ 60;
    final positionSeconds = positionInSeconds % 60;
    final durationMinutes = durationInSeconds ~/ 60;
    final durationSeconds = durationInSeconds % 60;

    return '${positionMinutes.toString().padLeft(2, '0')}:${positionSeconds.toString().padLeft(2, '0')} / ${durationMinutes.toString().padLeft(2, '0')}:${durationSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
