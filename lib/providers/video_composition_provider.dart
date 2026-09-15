import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_composition.dart';
import '../services/video_composition_service.dart';
import '../utils/audio_mixing_utils.dart';

/// Video composition state
class VideoCompositionState {
  final CompositionStatus status;
  final CompositionProgress? progress;
  final VideoComposition? result;
  final String? errorMessage;
  final List<AudioTrackInfo> audioTracks;
  final CompositionSettings settings;
  final bool isProcessing;

  const VideoCompositionState({
    this.status = CompositionStatus.pending,
    this.progress,
    this.result,
    this.errorMessage,
    this.audioTracks = const [],
    required this.settings,
    this.isProcessing = false,
  });

  VideoCompositionState copyWith({
    CompositionStatus? status,
    CompositionProgress? progress,
    VideoComposition? result,
    String? errorMessage,
    List<AudioTrackInfo>? audioTracks,
    CompositionSettings? settings,
    bool? isProcessing,
  }) {
    return VideoCompositionState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      audioTracks: audioTracks ?? this.audioTracks,
      settings: settings ?? this.settings,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Video composition state notifier
class VideoCompositionNotifier extends StateNotifier<VideoCompositionState> {
  final VideoCompositionService _service = VideoCompositionService();

  VideoCompositionNotifier(CompositionSettings settings)
      : super(VideoCompositionState(settings: settings)) {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Listen to progress updates
    _service.progressStream.listen((progress) {
      state = state.copyWith(progress: progress);
    });

    // Listen to status updates
    _service.statusStream.listen((status) {
      state = state.copyWith(status: status);
    });
  }

  /// Add audio track
  void addAudioTrack(AudioTrackInfo track) {
    final updatedTracks = [...state.audioTracks, track];
    state = state.copyWith(audioTracks: updatedTracks);
  }

  /// Remove audio track by index
  void removeAudioTrack(int index) {
    final updatedTracks = [...state.audioTracks];
    if (index >= 0 && index < updatedTracks.length) {
      updatedTracks.removeAt(index);
      state = state.copyWith(audioTracks: updatedTracks);
    }
  }

  /// Update audio track
  void updateAudioTrack(int index, AudioTrackInfo track) {
    final updatedTracks = [...state.audioTracks];
    if (index >= 0 && index < updatedTracks.length) {
      updatedTracks[index] = track;
      state = state.copyWith(audioTracks: updatedTracks);
    }
  }

  /// Update composition settings
  void updateSettings(CompositionSettings settings) {
    state = state.copyWith(settings: settings);
  }

  /// Start composition
  Future<void> compose({
    required String framePattern,
    required String outputPath,
    required String projectId,
    int? totalFrames,
    List<double>? trackVolumes,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final validation = AudioMixingUtils.validateTracks(state.audioTracks);
      if (validation != null) {
        throw VideoCompositionException(validation);
      }

      if (state.audioTracks.isEmpty) {
        throw VideoCompositionException('At least one audio track is required');
      }

      late VideoComposition result;

      if (state.audioTracks.length == 1) {
        result = await _service.composeVideo(
          framePattern: framePattern,
          audioPath: state.audioTracks.first.filePath,
          outputPath: outputPath,
          settings: state.settings,
          projectId: projectId,
          totalFrames: totalFrames,
        );
      } else {
        final audioPaths = state.audioTracks.map((t) => t.filePath).toList();
        result = await _service.composeVideoWithAudio(
          framePattern: framePattern,
          audioPaths: audioPaths,
          outputPath: outputPath,
          settings: state.settings,
          projectId: projectId,
          totalFrames: totalFrames,
          trackVolumes: trackVolumes,
        );
      }

      state = state.copyWith(
        result: result,
        status: CompositionStatus.completed,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        status: CompositionStatus.failed,
        isProcessing: false,
      );
    }
  }

  /// Cancel composition
  Future<void> cancel() async {
    await _service.cancel();
    state = state.copyWith(isProcessing: false);
  }

  /// Reset state
  void reset() {
    state = VideoCompositionState(settings: state.settings);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Default composition settings
final _defaultCompositionSettings = CompositionSettings(
  format: 'mp4',
  resolution: '1080p',
  fps: 30,
  videoBitrate: '3000k',
  audioBitrate: '128k',
  normalizeAudio: true,
);

/// Video composition provider
final videoCompositionProvider = StateNotifierProvider<
    VideoCompositionNotifier,
    VideoCompositionState>((ref) {
  return VideoCompositionNotifier(_defaultCompositionSettings);
});

/// Format provider
final compositionFormatProvider =
    StateProvider<String>((ref) => _defaultCompositionSettings.format);

/// Resolution provider
final compositionResolutionProvider =
    StateProvider<String>((ref) => _defaultCompositionSettings.resolution);

/// FPS provider
final compositionFpsProvider =
    StateProvider<int>((ref) => _defaultCompositionSettings.fps);

/// Video bitrate provider
final compositionVideoBitrateProvider =
    StateProvider<String>((ref) => _defaultCompositionSettings.videoBitrate);

/// Audio bitrate provider
final compositionAudioBitrateProvider =
    StateProvider<String>((ref) => _defaultCompositionSettings.audioBitrate);

/// Progress percentage provider
final compositionProgressPercentageProvider = Provider<double>((ref) {
  final state = ref.watch(videoCompositionProvider);
  final progress = state.progress;
  if (progress == null) return 0.0;
  return progress.percentComplete;
});

/// Formatted progress text provider
final compositionProgressTextProvider = Provider<String>((ref) {
  final state = ref.watch(videoCompositionProvider);
  final progress = state.progress;
  if (progress == null) return '0%';
  return '${(progress.percentComplete * 100).toStringAsFixed(1)}%';
});

/// ETA text provider
final compositionEtaTextProvider = Provider<String>((ref) {
  final state = ref.watch(videoCompositionProvider);
  final progress = state.progress;
  if (progress == null) return '--:--';

  final seconds = progress.estimatedSecondsRemaining;
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
});
