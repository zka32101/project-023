import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// 音声録音サービス
class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();

  late final AudioRecorder _recorder;
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPaused = false;

  factory AudioRecordingService() {
    return _instance;
  }

  AudioRecordingService._internal() {
    _recorder = AudioRecorder();
  }

  /// 録音中かどうかを判定
  bool get isRecording => _isRecording;

  /// 一時停止中かどうかを判定
  bool get isPaused => _isPaused;

  /// 現在の録音ファイルパス
  String? get currentRecordingPath => _currentRecordingPath;

  /// 録音を開始
  Future<bool> startRecording({String? customFilename}) async {
    try {
      // マイクへのアクセス確認
      if (!(await _recorder.hasPermission())) {
        return false;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docsDir.path}/dubbing_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      final filename = customFilename ?? 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = '${audioDir.path}/$filename';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _isPaused = false;
      return true;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }

  /// 録音を一時停止
  Future<bool> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) return false;

      await _recorder.pause();
      _isPaused = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 録音を再開
  Future<bool> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) return false;

      await _recorder.resume();
      _isPaused = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 録音を停止して保存
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _isPaused = false;

      return path ?? _currentRecordingPath;
    } catch (e) {
      return null;
    }
  }

  /// 録音をキャンセル
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        _isPaused = false;

        // ファイルを削除
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (file.existsSync()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Error canceling recording
    }
  }

  /// 音量レベルを取得（リアルタイム）
  Future<double> getAmplitude() async {
    try {
      if (!_isRecording || _isPaused) return 0.0;
      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;
    } catch (e) {
      return 0.0;
    }
  }

  /// クリーンアップ
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
