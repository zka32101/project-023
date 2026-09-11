import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/audio_track.dart';
import '../models/dubbing_project.dart';
import '../providers/dubbing_project_provider.dart';

/// オーディオトラックリスト管理ウィジェット
class AudioTrackList extends ConsumerWidget {
  final DubbingProject project;
  final Function(AudioTrack) onTrackSelected;
  final Function(String) onTrackDelete;

  const AudioTrackList({
    Key? key,
    required this.project,
    required this.onTrackSelected,
    required this.onTrackDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (project.tracks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: project.tracks.length,
      itemBuilder: (context, index) {
        final track = project.tracks[index];
        return _buildTrackTile(context, ref, track);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'トラックがありません',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '録音を追加してください',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(BuildContext context, WidgetRef ref, AudioTrack track) {
    final durationMs = track.duration;
    final seconds = (durationMs / 1000).toStringAsFixed(1);

    return Card(
      color: Colors.grey.shade800,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: ListTile(
        leading: Icon(
          track.isMuted ? Icons.volume_off : Icons.volume_up,
          color: track.isMuted ? Colors.red : AppColors.accent,
        ),
        title: Text(
          track.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '長さ: ${seconds}s • フレーム: ${track.startFrame} • ボリューム: ${(track.volume * 100).toInt()}%',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.grey.shade800,
          onSelected: (value) {
            _handleMenuAction(context, ref, track, value);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'toggle_mute',
              child: Row(
                children: [
                  Icon(
                    track.isMuted ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    track.isMuted ? 'ミュート解除' : 'ミュート',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '削除',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => onTrackSelected(track),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    AudioTrack track,
    String action,
  ) {
    switch (action) {
      case 'toggle_mute':
        final updatedTrack = track.copyWith(isMuted: !track.isMuted);
        ref.read(dubbingProjectProvider.notifier).updateTrackInProject(
          project.id,
          updatedTrack,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              track.isMuted ? 'ミュートを解除しました' : 'ミュートにしました',
            ),
          ),
        );
        break;

      case 'delete':
        _showDeleteConfirmation(context, ref, track);
        break;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AudioTrack track,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('トラックを削除'),
        content: Text('「${track.name}」を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(dubbingProjectProvider.notifier)
                  .removeTrackFromProject(project.id, track.id);
              onTrackDelete(track.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('トラックを削除しました')),
              );
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
