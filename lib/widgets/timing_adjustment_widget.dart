import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/audio_track.dart';
import '../models/dubbing_project.dart';
import '../providers/dubbing_project_provider.dart';

/// トラックの再生タイミング調整ウィジェット
class TimingAdjustmentWidget extends ConsumerWidget {
  final DubbingProject project;
  final AudioTrack track;
  final Function(AudioTrack) onTrackUpdated;

  const TimingAdjustmentWidget({
    Key? key,
    required this.project,
    required this.track,
    required this.onTrackUpdated,
  }) : super(key: key);

  /// フレーム数を時間文字列に変換（MM:SS.ms）
  String _framesToTimeString(int frames) {
    if (project.fps == 0) return '0:00.000';
    final totalSeconds = frames / project.fps;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toStringAsFixed(3);
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              'タイミング調整',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 開始フレーム調整
            _buildFrameAdjustment(
              context,
              ref,
              label: '開始フレーム',
              value: track.startFrame,
              maxValue: project.totalFrames,
              onChanged: (newFrame) {
                final updatedTrack = track.copyWith(startFrame: newFrame);
                _updateTrack(ref, updatedTrack);
                onTrackUpdated(updatedTrack);
              },
            ),
            const SizedBox(height: AppSizes.md),

            // ボリューム調整
            _buildVolumeAdjustment(
              context,
              ref,
              value: track.volume,
              onChanged: (newVolume) {
                final updatedTrack = track.copyWith(volume: newVolume);
                _updateTrack(ref, updatedTrack);
                onTrackUpdated(updatedTrack);
              },
            ),
            const SizedBox(height: AppSizes.md),

            // 再生時間表示
            _buildPlaybackInfo(),
          ],
        ),
      ),
    );
  }

  /// フレーム調整ウィジェット
  Widget _buildFrameAdjustment(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int value,
    required int maxValue,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            Text(
              'フレーム: $value / $maxValue',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: maxValue.toDouble(),
                divisions: maxValue > 0 ? maxValue : 1,
                onChanged: (newValue) {
                  onChanged(newValue.toInt());
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                _framesToTimeString(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ボリューム調整ウィジェット
  Widget _buildVolumeAdjustment(
    BuildContext context,
    WidgetRef ref, {
    required double value,
    required Function(double) onChanged,
  }) {
    final percentageValue = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ボリューム',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            Text(
              '$percentageValue%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
      ],
    );
  }

  /// 再生情報表示
  Widget _buildPlaybackInfo() {
    final durationMs = track.duration;
    final durationSeconds = (durationMs ~/ 1000).toStringAsFixed(2);

    // 開始フレームから終了フレームまでの時間を計算
    final endFrame = track.startFrame + ((track.duration * project.fps) ~/ 1000);
    final endFrameClamped = endFrame.clamp(0, project.totalFrames);

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '再生情報',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '開始: フレーム ${track.startFrame} (${_framesToTimeString(track.startFrame)})',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '終了: フレーム $endFrameClamped (${_framesToTimeString(endFrameClamped)})',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '音声長: $durationSeconds秒',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// トラックを更新
  void _updateTrack(WidgetRef ref, AudioTrack updatedTrack) {
    ref.read(dubbingProjectProvider.notifier).updateTrackInProject(
      project.id,
      updatedTrack,
    );
  }
}
