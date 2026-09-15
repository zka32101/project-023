import 'package:flutter/material.dart';
import '../models/video_composition.dart';

/// Composition progress display widget
class CompositionProgressWidget extends StatelessWidget {
  final CompositionProgress? progress;

  const CompositionProgressWidget({
    Key? key,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large circular progress indicator
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress!.percentComplete,
                  strokeWidth: 8,
                  minRadius: 80,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progress!.percentComplete * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '合成中...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Progress details
          _buildProgressDetails(context),
          const SizedBox(height: 32),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress!.percentComplete,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress details section
  Widget _buildProgressDetails(BuildContext context) {
    final eta = _formatTime(progress!.estimatedSecondsRemaining);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow('処理済みフレーム', '${progress!.processedFrames} / ${progress!.totalFrames}'),
          const SizedBox(height: 12),
          _buildDetailRow('進捗状況', progress!.getProgressString()),
          const SizedBox(height: 12),
          _buildDetailRow('予想残り時間', eta),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    if (seconds <= 0) return '計算中...';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
