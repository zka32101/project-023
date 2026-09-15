import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_composition.dart';
import '../providers/video_composition_provider.dart';
import '../utils/audio_mixing_utils.dart';
import '../widgets/composition_progress_widget.dart';
import '../widgets/output_format_selector.dart';
import '../widgets/audio_track_mixer.dart';

/// Video composition screen for combining frames with audio
class VideoCompositionScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String framePattern;
  final String outputPath;
  final int? totalFrames;

  const VideoCompositionScreen({
    Key? key,
    required this.projectId,
    required this.framePattern,
    required this.outputPath,
    this.totalFrames,
  }) : super(key: key);

  @override
  ConsumerState<VideoCompositionScreen> createState() =>
      _VideoCompositionScreenState();
}

class _VideoCompositionScreenState
    extends ConsumerState<VideoCompositionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compositionState = ref.watch(videoCompositionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ビデオ合成'),
        centerTitle: true,
        elevation: 0,
      ),
      body: compositionState.isProcessing
          ? _buildProcessingView(context, compositionState)
          : _buildCompositionView(context, theme),
      bottomNavigationBar: _buildBottomBar(context, compositionState),
    );
  }

  /// Build the composition view when not processing
  Widget _buildCompositionView(BuildContext context, ThemeData theme) {
    final compositionState = ref.watch(videoCompositionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frame information
          _buildFrameInfoCard(),
          const SizedBox(height: 24),

          // Output format selector
          OutputFormatSelector(
            onFormatChanged: (format) {
              final settings = compositionState.settings.copyWith(format: format);
              ref.read(videoCompositionProvider.notifier).updateSettings(settings);
            },
            onResolutionChanged: (resolution) {
              final settings = compositionState.settings.copyWith(resolution: resolution);
              ref.read(videoCompositionProvider.notifier).updateSettings(settings);
            },
            onFpsChanged: (fps) {
              final settings = compositionState.settings.copyWith(fps: fps);
              ref.read(videoCompositionProvider.notifier).updateSettings(settings);
            },
          ),
          const SizedBox(height: 24),

          // Audio track mixer
          AudioTrackMixer(
            tracks: compositionState.audioTracks,
            onAddTrack: (track) {
              ref.read(videoCompositionProvider.notifier).addAudioTrack(track);
            },
            onRemoveTrack: (index) {
              ref.read(videoCompositionProvider.notifier).removeAudioTrack(index);
            },
            onUpdateTrack: (index, track) {
              ref.read(videoCompositionProvider.notifier).updateAudioTrack(index, track);
            },
          ),
          const SizedBox(height: 24),

          // Metadata section
          _buildMetadataSection(),
          const SizedBox(height: 24),

          // Settings summary
          _buildSettingsSummary(compositionState),
        ],
      ),
    );
  }

  /// Build frame information card
  Widget _buildFrameInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フレーム情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('フレームパターン', widget.framePattern),
            const SizedBox(height: 8),
            _buildInfoRow('総フレーム数', widget.totalFrames?.toString() ?? '不明'),
            const SizedBox(height: 8),
            _buildInfoRow('出力パス', widget.outputPath),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build metadata section
  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'メタデータ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'ビデオタイトル',
                hintText: 'タイトルを入力してください（オプション）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: '制作者',
                hintText: '制作者名を入力してください（オプション）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build settings summary card
  Widget _buildSettingsSummary(VideoCompositionState state) {
    final settings = state.settings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '設定サマリー',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSettingRow('形式', settings.format.toUpperCase()),
            _buildSettingRow('解像度', settings.resolution),
            _buildSettingRow('フレームレート', '${settings.fps} fps'),
            _buildSettingRow('ビデオビットレート', settings.videoBitrate),
            _buildSettingRow('オーディオビットレート', settings.audioBitrate),
            _buildSettingRow('音声トラック数', '${state.audioTracks.length}'),
          ],
        ),
      ),
    );
  }

  /// Build setting row
  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Build processing view
  Widget _buildProcessingView(
      BuildContext context, VideoCompositionState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.status == CompositionStatus.processing)
            CompositionProgressWidget(
              progress: state.progress,
            )
          else if (state.status == CompositionStatus.failed)
            _buildErrorView(state)
          else if (state.status == CompositionStatus.completed)
            _buildCompletionView(state),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView(VideoCompositionState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          'エラーが発生しました',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            state.errorMessage ?? '不明なエラー',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ref.read(videoCompositionProvider.notifier).reset();
          },
          child: const Text('もう一度試す'),
        ),
      ],
    );
  }

  /// Build completion view
  Widget _buildCompletionView(VideoCompositionState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        Text(
          '完了しました',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (state.result != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Text(
                  'ファイルサイズ: ${state.result!.getFileSizeString()}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '保存先: ${state.result!.outputPath}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(state.result);
          },
          child: const Text('完了'),
        ),
      ],
    );
  }

  /// Build bottom action bar
  Widget _buildBottomBar(BuildContext context, VideoCompositionState state) {
    if (state.isProcessing) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ElevatedButton(
          onPressed: () {
            ref.read(videoCompositionProvider.notifier).cancel();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('キャンセル'),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: state.audioTracks.isEmpty
                  ? null
                  : () => _startComposition(context, state),
              child: const Text('合成開始'),
            ),
          ),
        ],
      ),
    );
  }

  /// Start composition process
  void _startComposition(BuildContext context, VideoCompositionState state) {
    final notifier = ref.read(videoCompositionProvider.notifier);
    final trackVolumes =
        state.audioTracks.map((t) => t.effectiveVolume).toList();

    notifier.compose(
      framePattern: widget.framePattern,
      outputPath: widget.outputPath,
      projectId: widget.projectId,
      totalFrames: widget.totalFrames,
      trackVolumes: trackVolumes,
    );
  }
}
