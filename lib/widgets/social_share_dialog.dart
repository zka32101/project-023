/// Social media share dialog for sharing videos to SNS platforms

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tsukuani/models/video_storage_models.dart';

/// Dialog for sharing videos to social media platforms
class SocialShareDialog extends StatefulWidget {
  /// The video to share
  final SavedVideo video;

  /// Callback when sharing is complete
  final VoidCallback? onShare;

  /// Custom share text (if not provided, generates default)
  final String? customShareText;

  const SocialShareDialog({
    Key? key,
    required this.video,
    this.onShare,
    this.customShareText,
  }) : super(key: key);

  @override
  State<SocialShareDialog> createState() => _SocialShareDialogState();
}

class _SocialShareDialogState extends State<SocialShareDialog> {
  late TextEditingController _shareTextController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _shareTextController = TextEditingController(
      text: widget.customShareText ?? _getDefaultShareText(),
    );
  }

  @override
  void dispose() {
    _shareTextController.dispose();
    super.dispose();
  }

  String _getDefaultShareText() {
    return 'Check out my video created with つくアニ! 🎬\n${widget.video.getDisplayName()}\n#つくアニ #animation #video';
  }

  void _shareToTwitter() async {
    _share('twitter');
  }

  void _shareToInstagram() async {
    _share('instagram');
  }

  void _shareToFacebook() async {
    _share('facebook');
  }

  void _shareToTikTok() async {
    _share('tiktok');
  }

  void _shareGeneral() async {
    _share('general');
  }

  Future<void> _share(String platform) async {
    setState(() => _isSharing = true);

    try {
      final shareText = _shareTextController.text;

      switch (platform) {
        case 'twitter':
          // Twitter share via URL scheme
          final twitterUrl =
              'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
          _launchURL(twitterUrl);

        case 'instagram':
          // Instagram share via system share (Instagram will receive from clipboard)
          await Share.share(shareText);

        case 'facebook':
          // Facebook share via URL scheme
          final facebookUrl =
              'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent("https://tsukuani.app")}&quote=${Uri.encodeComponent(shareText)}';
          _launchURL(facebookUrl);

        case 'tiktok':
          // TikTok share via system share
          await Share.share(shareText);

        default:
          // General share via system
          await Share.share(shareText);
      }

      widget.onShare?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _launchURL(String url) {
    // In a real app, use url_launcher package
    // For now, use Share as fallback
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.share, size: 28, color: Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Text(
                  'Share Video',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Share text editor
            Text(
              'Share Message',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _shareTextController,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter share message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Platform buttons
            Text(
              'Share To',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPlatformButton(
                  label: 'Twitter',
                  icon: Icons.tag,
                  color: const Color(0xFF1DA1F2),
                  onPressed: _isSharing ? null : _shareToTwitter,
                ),
                _buildPlatformButton(
                  label: 'Instagram',
                  icon: Icons.camera_alt,
                  color: const Color(0xFFE4405F),
                  onPressed: _isSharing ? null : _shareToInstagram,
                ),
                _buildPlatformButton(
                  label: 'Facebook',
                  icon: Icons.thumb_up,
                  color: const Color(0xFF1877F2),
                  onPressed: _isSharing ? null : _shareToFacebook,
                ),
                _buildPlatformButton(
                  label: 'TikTok',
                  icon: Icons.music_note,
                  color: const Color(0xFF000000),
                  onPressed: _isSharing ? null : _shareToTikTok,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // General share button
            ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareGeneral,
              icon: _isSharing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_isSharing ? 'Sharing...' : 'Share via System'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: _isSharing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
        ),
      ),
    );
  }
}
