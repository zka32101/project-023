import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../config/constants.dart';
import '../providers/collection_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/video_service.dart';
import '../models/project.dart';
import '../widgets/page_transition.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseStateProvider);
    final collectionCount = ref.watch(collectionCountProvider);
    final nextUnlocked = ref.watch(nextUnlockedCharacterProvider);
    final projectsUntilNext = ref.watch(projectsUntilNextUnlockProvider);
    final collectionProjects = ref.watch(collectionProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 作品コレクション'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Work count
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '作成済み',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          collectionCount.when(
                            data: (count) => Text(
                              '$count 本',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                            error: (_, __) => const Text('エラー'),
                            loading: () =>
                                const CircularProgressIndicator(),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.movie,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Projects grid
              collectionProjects.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.movie,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: AppSizes.md),
                            Text(
                              'まだ作品がありません',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSizes.md,
                      mainAxisSpacing: AppSizes.md,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _ProjectCard(
                        title: project.title,
                        duration: '${(project.videoDuration).toStringAsFixed(1)}秒',
                        onTap: () => _playVideo(context, project.projectId),
                        onLongPress: () => _showProjectMenu(context, project),
                      );
                    },
                  );
                },
                error: (err, __) => Text('エラー: $err'),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
              ),

              const SizedBox(height: AppSizes.xl),

              // Paywall or Character unlock section
              if (!purchaseState.isPurchased)
                _PaywallCard()
              else
                _UnlockCard(
                  nextCharacterId: nextUnlocked,
                  projectsUntilNext: projectsUntilNext,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String projectId) {
    Navigator.push(
      context,
      SlideUpPageRoute(
        page: _VideoPlayerScreen(projectId: projectId),
      ),
    );
  }

  void _showProjectMenu(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('名前を変更'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog(context, project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('複製'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プロジェクトを複製しました')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, Project project) {
    final controller = TextEditingController(text: project.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('プロジェクト名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'プロジェクト名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロジェクト名を変更しました')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('"${project.title}"を削除すると、復元できません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロジェクトを削除しました')),
              );
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String duration;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ProjectCard({
    Key? key,
    required this.title,
    required this.duration,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.movie, size: 60, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    duration,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(50),
            AppColors.accent.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, size: 40, color: AppColors.accent),
          const SizedBox(height: AppSizes.md),
          Text(
            '🔓 無制限作成は',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '¥${AppPrices.priceJPY}で解放!',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              onPressed: () => _purchase(context),
              child: const Text('今すぐ購入'),
            ),
          ),
        ],
      ),
    );
  }

  void _purchase(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('購入機能はまだ実装されていません')),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final String? nextCharacterId;
  final int projectsUntilNext;

  const _UnlockCard({
    Key? key,
    required this.nextCharacterId,
    required this.projectsUntilNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nextCharacterId == null) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          children: [
            const Icon(Icons.star, size: 40, color: Colors.green),
            const SizedBox(height: AppSizes.md),
            Text(
              'すべてのキャラクターが解放されました!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withAlpha(50),
            Theme.of(context).colorScheme.secondary.withAlpha(50),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 40, color: Colors.orange),
          const SizedBox(height: AppSizes.md),
          Text(
            '🎯 次のキャラまで:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'あと $projectsUntilNext 本',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: LinearProgressIndicator(
              value: 1.0 - (projectsUntilNext / 5.0).clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String projectId;

  const _VideoPlayerScreen({required this.projectId});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoPath =
          await VideoService().getProjectVideoPath(widget.projectId);
      if (!File(videoPath).existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画ファイルが見つかりません')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      controller.setLooping(true);

      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('動画を読み込めませんでした: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _initialized && _controller != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_isPlaying) {
                                _controller?.pause();
                              } else {
                                _controller?.play();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.amber,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}
