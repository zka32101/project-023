import 'package:audioplayers/audioplayers.dart';

/// 音声再生サービス
class AudioPlaybackService {
  static final AudioPlaybackService _instance =
      AudioPlaybackService._internal();

  late final AudioPlayer _player;
  bool _isPlaying = false;
  String? _currentAudioPath;

  factory AudioPlaybackService() {
    return _instance;
  }

  AudioPlaybackService._internal() {
    _player = AudioPlayer();

    // 再生完了イベント
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });

    // 再生エラー
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// 再生中かどうかを判定
  bool get isPlaying => _isPlaying;

  /// 現在再生中のファイルパス
  String? get currentAudioPath => _currentAudioPath;

  /// 現在の再生位置（ミリ秒）
  Future<int?> getCurrentPosition() async {
    try {
      final duration = await _player.getCurrentPosition();
      return duration?.inMilliseconds;
    } catch (e) {
      return null;
    }
  }

  /// 再生時間（ミリ秒）
  Future<int?> getDuration() async {
    try {
      final duration = await _player.getDuration();
      return duration?.inMilliseconds;
    } catch (e) {
      return null;
    }
  }

  /// 音声ファイルの再生を開始
  Future<bool> playAudio(String audioPath) async {
    try {
      _currentAudioPath = audioPath;
      await _player.play(DeviceFileSource(audioPath));
      _isPlaying = true;
      return true;
    } catch (e) {
      _isPlaying = false;
      return false;
    }
  }

  /// 再生を一時停止
  Future<bool> pausePlayback() async {
    try {
      if (!_isPlaying) return false;
      await _player.pause();
      _isPlaying = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 再生を再開
  Future<bool> resumePlayback() async {
    try {
      await _player.resume();
      _isPlaying = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 再生を停止
  Future<bool> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 再生位置を設定
  Future<bool> seek(int milliseconds) async {
    try {
      await _player.seek(Duration(milliseconds: milliseconds));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 音量を設定（0.0 - 1.0）
  Future<bool> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _player.setVolume(clampedVolume);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 再生速度を設定（0.5 - 2.0）
  Future<bool> setPlaybackRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.5, 2.0);
      await _player.setPlaybackRate(clampedRate);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ループ再生を設定
  Future<bool> setLooping(bool loop) async {
    try {
      await _player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// クリーンアップ
  Future<void> dispose() async {
    await _player.dispose();
  }
}
