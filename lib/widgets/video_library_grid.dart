/// Video library grid widget for displaying saved videos

import 'package:flutter/material.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/screens/video_preview_screen.dart';
import 'package:tsukuani/widgets/social_share_dialog.dart';

/// Grid widget for displaying videos
class VideoLibraryGrid extends StatefulWidget {
  /// List of videos to display
  final List<SavedVideo> videos;

  /// Number of columns in grid
  final int crossAxisCount;

  /// Callback when video is selected
  final ValueChanged<SavedVideo>? onVideoSelected;

  /// Callback when video is deleted
  final VoidCallback? onVideoDeleted;

  /// Callback when video is shared
  final VoidCallback? onVideoShared;

  /// Whether to show empty state message
  final bool showEmptyState;

  const VideoLibraryGrid({
    Key? key,
    required this.videos,
    this.crossAxisCount = 2,
    this.onVideoSelected,
    this.onVideoDeleted,
    this.onVideoShared,
    this.showEmptyState = true,
  }) : super(key: key);

  @override
  State<VideoLibraryGrid> createState() => _VideoLibraryGridState();
}

class _VideoLibraryGridState extends State<VideoLibraryGrid> {
  late Map<String, bool> _selectedVideos;

  @override
  void initState() {
    super.initState();
    _selectedVideos = {};
  }

  void _toggleVideoSelection(String videoId) {
    setState(() {
      _selectedVideos[videoId] = !(_selectedVideos[videoId] ?? false);
    });
  }

  void _showVideoMenu(BuildContext context, SavedVideo video) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                _openVideoPreview(video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _showShareDialog(video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _showVideoDetails(video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download functionality coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteVideo(video);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPreview(SavedVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(
          video: video,
          onVideoDeleted: widget.onVideoDeleted,
          onVideoShared: widget.onVideoShared,
        ),
      ),
    );
  }

  void _showShareDialog(SavedVideo video) {
    showDialog(
      context: context,
      builder: (context) => SocialShareDialog(
        video: video,
        onShare: () {
          widget.onVideoShared?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showVideoDetails(SavedVideo video) {
    final metadata = video.metadata;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.getDisplayName()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Resolution', metadata.getResolutionString()),
              _buildDetailRow('File Size', metadata.getFileSizeString()),
              _buildDetailRow('Format', metadata.format.toUpperCase()),
              _buildDetailRow('Frame Rate', '${metadata.fps} fps'),
              _buildDetailRow('Duration', '${metadata.durationSeconds.toStringAsFixed(1)}s'),
              _buildDetailRow('Created', _formatDateTime(metadata.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(SavedVideo video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Delete "${video.getDisplayName()}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onVideoDeleted?.call();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      if (widget.showEmptyState) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No videos found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        final isSelected = _selectedVideos[video.id] ?? false;

        return GestureDetector(
          onTap: () {
            widget.onVideoSelected?.call(video);
            _openVideoPreview(video);
          },
          onLongPress: () => _showVideoMenu(context, video),
          child: Stack(
            children: [
              // Placeholder/thumbnail background
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF6366F1), width: 3)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.metadata.getResolutionString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Overlay with video info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        video.metadata.getFileSizeString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        video.getDisplayName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Play button overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
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
