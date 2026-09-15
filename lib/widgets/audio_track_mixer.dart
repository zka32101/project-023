import 'package:flutter/material.dart';
import '../utils/audio_mixing_utils.dart';

/// Audio track mixer widget for managing multiple audio tracks
class AudioTrackMixer extends StatefulWidget {
  final List<AudioTrackInfo> tracks;
  final ValueChanged<AudioTrackInfo> onAddTrack;
  final ValueChanged<int> onRemoveTrack;
  final Function(int, AudioTrackInfo) onUpdateTrack;

  const AudioTrackMixer({
    Key? key,
    required this.tracks,
    required this.onAddTrack,
    required this.onRemoveTrack,
    required this.onUpdateTrack,
  }) : super(key: key);

  @override
  State<AudioTrackMixer> createState() => _AudioTrackMixerState();
}

class _AudioTrackMixerState extends State<AudioTrackMixer> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'オーディオトラック',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTrackDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('追加'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.tracks.isEmpty)
              _buildEmptyState()
            else
              _buildTracksList(),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'オーディオトラックが追加されていません',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '上の「追加」ボタンからトラックを追加してください',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build tracks list
  Widget _buildTracksList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        return _buildTrackTile(index, track);
      },
    );
  }

  /// Build track tile
  Widget _buildTrackTile(int index, AudioTrackInfo track) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.filePath,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTrackDialog(index, track);
                    } else if (value == 'delete') {
                      widget.onRemoveTrack(index);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('編集'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('削除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVolumeControl(index, track),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ボリューム: ${(track.volume * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (track.isMuted)
                  Chip(
                    label: const Text('ミュート'),
                    avatar: const Icon(Icons.volume_off, size: 16),
                    onDeleted: () {
                      final updatedTrack = AudioTrackInfo(
                        id: track.id,
                        name: track.name,
                        filePath: track.filePath,
                        volume: track.volume,
                        isMuted: false,
                        startMs: track.startMs,
                        durationMs: track.durationMs,
                      );
                      widget.onUpdateTrack(index, updatedTrack);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build volume control slider
  Widget _buildVolumeControl(int index, AudioTrackInfo track) {
    return Row(
      children: [
        Icon(
          Icons.volume_down,
          size: 16,
          color: Colors.grey.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: track.volume.clamp(0.0, 1.0),
            onChanged: (value) {
              final updatedTrack = AudioTrackInfo(
                id: track.id,
                name: track.name,
                filePath: track.filePath,
                volume: value,
                isMuted: track.isMuted,
                startMs: track.startMs,
                durationMs: track.durationMs,
              );
              widget.onUpdateTrack(index, updatedTrack);
            },
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.volume_up,
          size: 16,
          color: Colors.grey.withOpacity(0.6),
        ),
      ],
    );
  }

  /// Show add track dialog
  void _showAddTrackDialog() {
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('オーディオトラック追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'トラック名',
                  hintText: 'トラック1',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: 'ファイルパス',
                  hintText: '/path/to/audio.mp3',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  pathController.text.isNotEmpty) {
                final newTrack = AudioTrackInfo(
                  id: 'track_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  filePath: pathController.text,
                  volume: 1.0,
                  isMuted: false,
                );
                widget.onAddTrack(newTrack);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  /// Show edit track dialog
  void _showEditTrackDialog(int index, AudioTrackInfo track) {
    final nameController = TextEditingController(text: track.name);
    final pathController = TextEditingController(text: track.filePath);
    var isMuted = track.isMuted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('トラック編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'トラック名',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'ファイルパス',
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('ミュート'),
                  value: isMuted,
                  onChanged: (value) {
                    setState(() => isMuted = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTrack = AudioTrackInfo(
                  id: track.id,
                  name: nameController.text,
                  filePath: pathController.text,
                  volume: track.volume,
                  isMuted: isMuted,
                  startMs: track.startMs,
                  durationMs: track.durationMs,
                );
                widget.onUpdateTrack(index, updatedTrack);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
