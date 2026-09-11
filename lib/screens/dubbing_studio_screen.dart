import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/custom_character.dart';
import '../models/audio_track.dart';
import '../models/dubbing_project.dart';
import '../providers/dubbing_project_provider.dart';
import '../services/audio_recording_service.dart';
import '../utils/logger.dart';
import '../widgets/waveform_painter.dart';
import '../widgets/volume_meter.dart';

/// アフレコスタジオ画面
class DubbingStudioScreen extends ConsumerStatefulWidget {
  final CustomCharacter character;
  final int fps;
  final int totalFrames;
  final DubbingProject? existingProject;

  const DubbingStudioScreen({
    Key? key,
    required this.character,
    required this.fps,
    required this.totalFrames,
    this.existingProject,
  }) : super(key: key);

  @override
  ConsumerState<DubbingStudioScreen> createState() =>
      _DubbingStudioScreenState();
}

class _DubbingStudioScreenState extends ConsumerState<DubbingStudioScreen> {
  late final AudioRecordingService _recordingService;

  bool _isRecording = false;
  bool _isPaused = false;
  double _currentAmplitude = 0.0;
  int _recordingDuration = 0;

  // リアルタイム波形データ
  final List<double> _amplitudes = [];
  static const int _maxAmplitudeSamples = 200;

  @override
  void initState() {
    super.initState();
    _recordingService = AudioRecordingService();
    _startAmplitudeMonitoring();
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  /// 音量レベルをリアルタイムで監視
  void _startAmplitudeMonitoring() {
    Future.doWhile(() async {
      if (_isRecording && !_isPaused) {
        final amplitude = await _recordingService.getAmplitude();
        if (mounted) {
          setState(() {
            _currentAmplitude = amplitude;
            _amplitudes.add(amplitude);
            if (_amplitudes.length > _maxAmplitudeSamples) {
              _amplitudes.removeAt(0);
            }
          });
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return _isRecording;
    });
  }

  /// 録音を開始
  Future<void> _startRecording() async {
    try {
      final success = await _recordingService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordingDuration = 0;
          _amplitudes.clear();
        });
        _startRecordingTimer();
      } else {
        _showError('マイクへのアクセスに失敗しました');
      }
    } catch (e) {
      AppLogger.error('Start recording', e);
      _showError('録音開始エラー: $e');
    }
  }

  /// 録音を一時停止
  Future<void> _pauseRecording() async {
    try {
      final success = await _recordingService.pauseRecording();
      if (success) {
        setState(() {
          _isPaused = true;
        });
      }
    } catch (e) {
      AppLogger.error('Pause recording', e);
      _showError('一時停止エラー: $e');
    }
  }

  /// 録音を再開
  Future<void> _resumeRecording() async {
    try {
      final success = await _recordingService.resumeRecording();
      if (success) {
        setState(() {
          _isPaused = false;
        });
      }
    } catch (e) {
      AppLogger.error('Resume recording', e);
      _showError('再開エラー: $e');
    }
  }

  /// 録音を停止して保存
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final audioPath = await _recordingService.stopRecording();
      if (audioPath != null && mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // 新規トラックを作成
        final track = AudioTrack(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Track ${DateTime.now().toString().split(' ')[1]}',
          audioPath: audioPath,
          startFrame: 0,
          volume: 1.0,
          isMuted: false,
          createdAt: DateTime.now(),
          duration: _recordingDuration * 1000, // ミリ秒に変換
        );

        _showRecordingComplete(track);
      }
    } catch (e) {
      AppLogger.error('Stop recording', e);
      _showError('停止エラー: $e');
    }
  }

  /// 録音をキャンセル
  Future<void> _cancelRecording() async {
    try {
      await _recordingService.cancelRecording();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _recordingDuration = 0;
          _amplitudes.clear();
        });
      }
    } catch (e) {
      AppLogger.error('Cancel recording', e);
      _showError('キャンセルエラー: $e');
    }
  }

  /// 録音時間タイマー
  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration++;
        });
      }
      return _isRecording;
    });
  }

  /// 録音完了ダイアログ
  void _showRecordingComplete(AudioTrack track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('録音完了'),
        content: const Text('トラックを保存しました。プロジェクトに追加しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _discardTrack();
            },
            child: const Text('破棄'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addTrackToProject(track);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// プロジェクトにトラックを追加
  Future<void> _addTrackToProject(AudioTrack track) async {
    try {
      // プロジェクトが存在しない場合は新規作成
      if (widget.existingProject == null) {
        final notifier = ref.read(dubbingProjectProvider.notifier);
        final project = await notifier.createProject(
          characterId: widget.character.id,
          projectName: '${widget.character.name} - アフレコ',
          fps: widget.fps,
          totalFrames: widget.totalFrames,
        );
        await notifier.addTrackToProject(project.id, track);
      } else {
        final notifier = ref.read(dubbingProjectProvider.notifier);
        await notifier.addTrackToProject(widget.existingProject!.id, track);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('トラックを保存しました')),
        );
      }
    } catch (e) {
      AppLogger.error('Add track to project', e);
      _showError('保存エラー: $e');
    }
  }

  /// トラックを破棄
  void _discardTrack() {
    // 一時的に保存されたファイルは削除される
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('トラックを破棄しました')),
    );
  }

  /// エラー表示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('アフレコスタジオ'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // キャラクター情報
              _buildCharacterInfo(),
              const SizedBox(height: AppSizes.lg),

              // 波形表示
              _buildWaveformDisplay(),
              const SizedBox(height: AppSizes.lg),

              // 音量メーター
              _buildVolumeMeter(),
              const SizedBox(height: AppSizes.lg),

              // 録音時間表示
              _buildRecordingDuration(),
              const SizedBox(height: AppSizes.lg),

              // 制御ボタン
              _buildControlButtons(),
              const SizedBox(height: AppSizes.lg),

              // プロジェクト情報
              if (widget.existingProject != null) _buildProjectInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterInfo() {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            if (widget.character.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  widget.character.imagePath.startsWith('/')
                      ? File(widget.character.imagePath)
                      : File(widget.character.imagePath),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade700,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.fps} FPS • ${widget.totalFrames} フレーム',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformDisplay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      height: 150,
      child: CustomPaint(
        painter: WaveformPainter(
          amplitudes: _amplitudes,
          isRecording: _isRecording,
        ),
      ),
    );
  }

  Widget _buildVolumeMeter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '音量レベル',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        VolumeMeter(
          amplitude: _currentAmplitude,
          isRecording: _isRecording,
        ),
      ],
    );
  }

  Widget _buildRecordingDuration() {
    final minutes = (_recordingDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDuration % 60).toString().padLeft(2, '0');

    return Center(
      child: Text(
        '$minutes:$seconds',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // 記録コントロール
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!_isRecording)
              FloatingActionButton.extended(
                onPressed: _startRecording,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('録音開始'),
              )
            else if (_isPaused)
              FloatingActionButton.extended(
                onPressed: _resumeRecording,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.play_arrow),
                label: const Text('再開'),
              )
            else
              FloatingActionButton.extended(
                onPressed: _pauseRecording,
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.pause),
                label: const Text('一時停止'),
              ),
            if (_isRecording)
              FloatingActionButton.extended(
                onPressed: _stopRecording,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
            if (_isRecording)
              FloatingActionButton.extended(
                onPressed: _cancelRecording,
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.close),
                label: const Text('キャンセル'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プロジェクト情報',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey.shade800,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.existingProject!.tracks.length} トラック',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '作成: ${widget.existingProject!.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
