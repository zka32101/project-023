import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../config/constants.dart';
import '../providers/frame_provider.dart';
import '../providers/voiceover_provider.dart';
import '../services/video_service.dart';
import '../utils/logger.dart';
import '../widgets/live_preview_widget.dart';

// Lets the user record a voice narration while watching their animation
// loop, then confirms or discards it before returning to the export flow.
class VoiceoverStudioScreen extends ConsumerStatefulWidget {
  final String projectId;
  final int fps;

  const VoiceoverStudioScreen({
    Key? key,
    required this.projectId,
    required this.fps,
  }) : super(key: key);

  @override
  ConsumerState<VoiceoverStudioScreen> createState() =>
      _VoiceoverStudioScreenState();
}

class _VoiceoverStudioScreenState extends ConsumerState<VoiceoverStudioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  VideoPlayerController? _playbackController;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  bool _isPlaying = false;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _recorder.dispose();
    _playbackController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        _showSnack('マイクの使用が許可されていません', isError: true);
      }
      return;
    }

    final path = await VideoService().getVoiceoverPath(widget.projectId);
    if (File(path).existsSync()) {
      await File(path).delete();
    }

    try {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      ref.read(voiceoverProvider.notifier).startRecording();
      _elapsed = Duration.zero;
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() {});
    } catch (e) {
      AppLogger.error('Voiceover recording start error', e);
      if (mounted) _showSnack('録音を開始できませんでした', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    _elapsedTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) {
        ref.read(voiceoverProvider.notifier).finishRecording(path, _elapsed);
      } else {
        ref.read(voiceoverProvider.notifier).discard();
      }
      setState(() {});
    } catch (e) {
      AppLogger.error('Voiceover recording stop error', e);
      if (mounted) _showSnack('録音の保存に失敗しました', isError: true);
    }
  }

  Future<void> _togglePlayback(String path) async {
    if (_playbackController == null) {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.addListener(() {
        if (!controller.value.isPlaying && _isPlaying) {
          setState(() => _isPlaying = false);
        }
      });
      _playbackController = controller;
    }

    if (_isPlaying) {
      await _playbackController!.pause();
    } else {
      await _playbackController!.seekTo(Duration.zero);
      await _playbackController!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _reRecord() async {
    await _playbackController?.dispose();
    _playbackController = null;
    _isPlaying = false;
    ref.read(voiceoverProvider.notifier).discard();
    setState(() {});
  }

  void _confirmAndReturn() {
    final state = ref.read(voiceoverProvider);
    Navigator.pop(context, state.audioPath);
  }

  void _skip() {
    ref.read(voiceoverProvider.notifier).discard();
    Navigator.pop(context, null);
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final voiceoverState = ref.watch(voiceoverProvider);
    final framePathsAsync = ref.watch(framePathsProvider(widget.projectId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('アフレコスタジオ'),
        actions: [
          TextButton(
            onPressed: voiceoverState.status == VoiceoverStatus.recording
                ? null
                : _skip,
            child: const Text('スキップ', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSizes.lg),
          Center(
            child: framePathsAsync.when(
              data: (paths) => paths.length >= 3
                  ? LivePreviewWidget(
                      framePaths: paths, fps: widget.fps, size: 220)
                  : const Text('プレビューできるフレームがありません',
                      style: TextStyle(color: Colors.white38)),
              loading: () =>
                  const CircularProgressIndicator(color: AppColors.accent),
              error: (_, __) => const Text('プレビューを読み込めませんでした',
                  style: TextStyle(color: Colors.white38)),
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildStatusText(voiceoverState.status),
          const SizedBox(height: AppSizes.lg),
          _buildControls(voiceoverState),
          const Spacer(),
          if (voiceoverState.status == VoiceoverStatus.recorded)
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                  ),
                  onPressed: _confirmAndReturn,
                  icon: const Icon(Icons.check),
                  label: const Text('この録音を使う',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(VoiceoverStatus status) {
    final text = switch (status) {
      VoiceoverStatus.idle => 'マイクボタンを押して録音開始',
      VoiceoverStatus.recording => '録音中… もう一度押して停止',
      VoiceoverStatus.recorded => '録音完了！再生して確認できます',
    };
    return Text(text, style: const TextStyle(color: Colors.white60, fontSize: 13));
  }

  Widget _buildControls(VoiceoverState state) {
    switch (state.status) {
      case VoiceoverStatus.idle:
        return _RecordButton(onTap: _startRecording, isRecording: false);
      case VoiceoverStatus.recording:
        return _RecordButton(onTap: _stopRecording, isRecording: true);
      case VoiceoverStatus.recorded:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 48,
              icon: Icon(
                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: AppColors.accent,
              ),
              onPressed: () => _togglePlayback(state.audioPath!),
            ),
            const SizedBox(width: AppSizes.xl),
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.refresh, color: Colors.white60),
              onPressed: _reRecord,
              tooltip: '撮り直す',
            ),
          ],
        );
    }
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRecording;

  const _RecordButton({required this.onTap, required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.red : AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.red : AppColors.accent)
                  .withAlpha(120),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          color: Colors.black,
          size: 36,
        ),
      ),
    );
  }
}
