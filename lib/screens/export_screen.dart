import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/export_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/frame_provider.dart';
import '../providers/voiceover_provider.dart';
import '../services/video_service.dart';
import '../widgets/live_preview_widget.dart';
import 'complete_screen.dart';
import 'voiceover_studio_screen.dart';

class ExportScreen extends ConsumerWidget {
  final String projectId;
  final int frameCount;
  final int fps;

  const ExportScreen({
    Key? key,
    required this.projectId,
    required this.frameCount,
    required this.fps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportStateProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
    final duration = frameCount > 0 ? frameCount / fps : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('動画を出力する'),
        automaticallyImplyLeading: exportState.status != ExportStatus.processing,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ファイル情報:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.md),
                      _InfoRow('フレーム', frameCount.toString()),
                      _InfoRow('fps', fps.toString()),
                      _InfoRow('予想時間', '${duration.toStringAsFixed(2)}秒'),
                      _InfoRow('解像度', purchaseState.isPurchased ? '1080p (推奨)' : '720p'),
                      _InfoRow('ファイルサイズ', '~${_estimateSize(frameCount)}MB'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Preview
              _PreviewSection(projectId: projectId, fps: fps),
              const SizedBox(height: AppSizes.lg),

              // Paywall or Export Button
              if (!purchaseState.isPurchased)
                _paywallSection(context, purchaseState)
              else
                _purchasedSection(context, ref, exportState),

              const SizedBox(height: AppSizes.lg),

              // Progress Indicator
              if (exportState.status == ExportStatus.processing)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: exportState.progressPercentage / 100.0,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      '書き出し中... ${exportState.progressPercentage}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

              if (exportState.status == ExportStatus.failed)
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'エラーが発生しました',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        exportState.errorMessage ?? 'Unknown error',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paywallSection(BuildContext context, PurchaseState purchaseState) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(50),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, size: 40, color: AppColors.accent),
          const SizedBox(height: AppSizes.md),
          Text(
            'まだ書出できません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '¥${AppPrices.priceJPY}で無制限に!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: () => _purchase(context),
                  child: const Text('今すぐ購入'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('後でする'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _purchasedSection(
      BuildContext context, WidgetRef ref, ExportState exportState) {
    final selectedResolution = ref.watch(exportResolutionProvider);
    final selectedAudio = ref.watch(audioProvider);
    final voiceoverState = ref.watch(voiceoverProvider);

    return Column(
      children: [
        // Voiceover narration
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(
                voiceoverState.status == VoiceoverStatus.recorded
                    ? Icons.mic
                    : Icons.mic_none,
                color: voiceoverState.status == VoiceoverStatus.recorded
                    ? AppColors.accent
                    : Colors.white54,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アフレコ (ナレーション)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      voiceoverState.status == VoiceoverStatus.recorded
                          ? '録音済み'
                          : '未録音（任意）',
                      style: TextStyle(
                        color: voiceoverState.status ==
                                VoiceoverStatus.recorded
                            ? AppColors.accent
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openVoiceoverStudio(context, ref),
                child: Text(
                  voiceoverState.status == VoiceoverStatus.recorded
                      ? '撮り直す'
                      : '録音する',
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // BGM selector
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BGM/効果音を選択',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.sm,
                children: AudioSelection.values.map((audio) {
                  final isSelected = selectedAudio == audio;
                  return FilterChip(
                    label: Text(audio.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(audioProvider.notifier).state = audio;
                      }
                    },
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Resolution selector
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '解像度を選択',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: _ResolutionOption(
                      label: '720p',
                      subtitle: '標準',
                      isSelected: selectedResolution == VideoResolution.resolution720p,
                      onTap: () => ref
                          .read(exportResolutionProvider.notifier)
                          .state = VideoResolution.resolution720p,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _ResolutionOption(
                      label: '1080p',
                      subtitle: 'プレミアム',
                      isSelected: selectedResolution == VideoResolution.resolution1080p,
                      onTap: () => ref
                          .read(exportResolutionProvider.notifier)
                          .state = VideoResolution.resolution1080p,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          icon: const Icon(Icons.cloud_upload),
          label: const Text(
            '書き出しを開始',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onPressed: exportState.status == ExportStatus.processing
              ? null
              : () => _startExport(context, ref),
        ),
      ],
    );
  }

  Future<void> _openVoiceoverStudio(
      BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VoiceoverStudioScreen(projectId: projectId, fps: fps),
      ),
    );
  }

  void _purchase(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('購入機能はまだ実装されていません')),
    );
  }

  void _startExport(BuildContext context, WidgetRef ref) {
    final isPurchased = ref.read(purchaseStateProvider).isPurchased;
    final selectedResolution = ref.read(exportResolutionProvider);

    // Check resolution is available for user tier
    if (selectedResolution == VideoResolution.resolution1080p && !isPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1080pは購入後に利用可能です')),
      );
      return;
    }

    ref.read(exportStateProvider.notifier).startExport();
    final voiceoverAudioPath = ref.read(voiceoverProvider).audioPath;

    VideoService()
        .createVideoFromFrames(
          projectId: projectId,
          fps: fps,
          resolution: selectedResolution,
          audioPath: voiceoverAudioPath,
          onProgress: (percentage) {
            ref.read(exportStateProvider.notifier).updateProgress(percentage);
          },
        )
        .then((file) {
          if (file != null) {
            ref.read(exportStateProvider.notifier).completeExport(file.path);
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CompleteScreen(
                    projectId: projectId,
                    videoPath: file.path,
                  ),
                ),
              );
            }
          } else {
            ref.read(exportStateProvider.notifier).failExport('動画の生成に失敗しました');
          }
        })
        .catchError((Object e) {
          ref.read(exportStateProvider.notifier).failExport(e.toString());
        });
  }

  int _estimateSize(int frameCount) {
    return (frameCount * 0.5).ceil();
  }
}

class _PreviewSection extends ConsumerStatefulWidget {
  final String projectId;
  final int fps;

  const _PreviewSection({required this.projectId, required this.fps});

  @override
  ConsumerState<_PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends ConsumerState<_PreviewSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'プレビュー再生',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white60,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSizes.md),
            Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final framePathsAsync =
                      ref.watch(framePathsProvider(widget.projectId));
                  return framePathsAsync.when(
                    data: (paths) => paths.length >= 3
                        ? LivePreviewWidget(
                            framePaths: paths,
                            fps: widget.fps,
                            size: 220,
                          )
                        : const Text(
                            '3枚以上のフレームでプレビューできます',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                    loading: () => const CircularProgressIndicator(
                        color: AppColors.accent),
                    error: (_, __) => const Text(
                      'プレビューを読み込めませんでした',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResolutionOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withAlpha(100)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : Colors.white.withAlpha(30),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
