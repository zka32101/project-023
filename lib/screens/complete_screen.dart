import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../config/constants.dart';
import '../providers/camera_provider.dart';
import '../providers/social_share_provider.dart';
import '../services/video_service.dart';
import '../widgets/premiere_overlay.dart';
import '../utils/logger.dart';

class CompleteScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String videoPath;

  const CompleteScreen({
    Key? key,
    required this.projectId,
    required this.videoPath,
  }) : super(key: key);

  @override
  ConsumerState<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends ConsumerState<CompleteScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isSaving = false;
  bool _showPremiere = true;
  bool _isGeneratingMakingOf = false;

  late AnimationController _celebrationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
    _celebrationController.forward();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final file = File(widget.videoPath);
    if (!file.existsSync()) return;

    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.error('Video player init error', e);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraStateProvider);
    final fps = cameraState.fpsPreset;
    final frameCount = cameraState.frameCount;
    final duration = frameCount > 0 ? (frameCount / fps) : 0.0;
    final fileSizeKb = File(widget.videoPath).existsSync()
        ? (File(widget.videoPath).lengthSync() / 1024).round()
        : 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header celebration
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg, AppSizes.xl, AppSizes.lg, AppSizes.md),
                    child: ScaleTransition(
                      scale: _bounceAnimation,
                      child: Column(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 8),
                          Text(
                            '完成しました！',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: AppTypography.weightBold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'あなたの力作をみんなに見せよう！',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.white.withAlpha(200),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Video preview
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        child: Container(
                          color: Colors.black,
                          child: _videoInitialized &&
                                  _videoController != null
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : _buildVideoPlaceholder(),
                        ),
                      ),
                    ),
                  ),

                  // File info chip row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg, vertical: AppSizes.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoChip(
                            icon: Icons.timer_outlined,
                            label:
                                '${duration.toStringAsFixed(1)}秒'),
                        const SizedBox(width: AppSizes.sm),
                        _InfoChip(
                            icon: Icons.photo_library_outlined,
                            label: '$frameCount フレーム'),
                        const SizedBox(width: AppSizes.sm),
                        _InfoChip(
                            icon: Icons.storage_outlined,
                            label: '${fileSizeKb}KB'),
                      ],
                    ),
                  ),

                  // Primary action: SNS share
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryStart,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          elevation: AppSizes.elevationLarge,
                        ),
                        onPressed: () => _shareSocial(),
                        icon: const Icon(Icons.share),
                        label: const Text(
                          'SNSで共有する',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.sm),

                  // Making-of: slow-motion cut of the frame-by-frame process
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sm),
                        ),
                        onPressed: _isGeneratingMakingOf
                            ? null
                            : () => _generateAndShareMakingOf(),
                        icon: _isGeneratingMakingOf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.theaters, size: 18),
                        label: Text(
                          _isGeneratingMakingOf
                              ? '作成中...'
                              : '🎬 メイキング動画をシェア',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.sm),

                  // Secondary actions row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            icon: _isSaving
                                ? Icons.hourglass_top
                                : Icons.photo_library,
                            label: _isSaving ? '保存中...' : 'カメラロール',
                            onTap: _isSaving
                                ? null
                                : () => _saveToGallery(),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.add_circle_outline,
                            label: '新しく作る',
                            onTap: () => _createNew(context),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.home_outlined,
                            label: 'ホーム',
                            onTap: () => _goHome(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),

            // Premiere overlay (first play only)
            if (_showPremiere)
              PremiereOverlay(
                onComplete: () {
                  setState(() => _showPremiere = false);
                  _videoController?.play();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie, size: 60, color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            File(widget.videoPath).existsSync()
                ? '動画を読み込み中...'
                : '動画ファイルが見つかりません',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToGallery() async {
    if (!File(widget.videoPath).existsSync()) {
      _showSnack('動画ファイルが見つかりません', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ImageGallerySaver.saveFile(
        widget.videoPath,
        name: 'tsukuani_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] != true) {
        throw Exception(result['errorMessage'] ?? 'Unknown error');
      }
      if (mounted) _showSnack('カメラロールに保存しました！');
    } catch (e) {
      AppLogger.error('Gallery save error', e);
      if (mounted) _showSnack('保存に失敗しました: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareSocial() async {
    if (!File(widget.videoPath).existsSync()) {
      _showSnack('動画ファイルが見つかりません', isError: true);
      return;
    }

    try {
      final cameraState = ref.read(cameraStateProvider);
      final duration = cameraState.frameCount > 0
          ? cameraState.frameCount / cameraState.fpsPreset
          : 0.0;

      final shareService = SocialShareService();
      final shareText = shareService.generateShareText(
        '作品',
        cameraState.frameCount,
        duration,
      );

      await Share.shareXFiles(
        [XFile(widget.videoPath, mimeType: 'video/mp4')],
        text: shareText,
      );

      // Track share event
      shareService.trackShareEvent(widget.projectId, 'share_plus');
    } catch (e) {
      AppLogger.error('Share error', e);
      if (mounted) _showSnack('共有に失敗しました', isError: true);
    }
  }

  Future<void> _generateAndShareMakingOf() async {
    setState(() => _isGeneratingMakingOf = true);
    try {
      final cameraState = ref.read(cameraStateProvider);
      final file = await VideoService().createMakingOfVideo(
        projectId: widget.projectId,
        originalFps: cameraState.fpsPreset,
        onProgress: (_) {},
      );

      if (file == null) {
        if (mounted) _showSnack('メイキング動画の生成に失敗しました', isError: true);
        return;
      }

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'video/mp4')],
        text: '作品ができるまでの過程だよ！ #つくアニ',
      );
    } catch (e) {
      AppLogger.error('Making-of generation error', e);
      if (mounted) _showSnack('メイキング動画の生成に失敗しました', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingMakingOf = false);
    }
  }

  void _createNew(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: AppSizes.sm),
          decoration: BoxDecoration(
            gradient: widget.onTap != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(40),
                      Colors.white.withAlpha(20),
                    ],
                  )
                : null,
            color: widget.onTap == null ? Colors.white.withAlpha(10) : null,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: widget.onTap != null
                  ? AppColors.accent.withAlpha(150)
                  : Colors.white.withAlpha(30),
              width: 2,
            ),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(50),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.onTap != null ? AppColors.white : Colors.white38,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.onTap != null ? AppColors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
