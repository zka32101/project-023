import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceoverStatus { idle, recording, recorded }

final voiceoverProvider =
    StateNotifierProvider<VoiceoverNotifier, VoiceoverState>((ref) {
  return VoiceoverNotifier();
});

class VoiceoverState {
  final VoiceoverStatus status;
  final String? audioPath;
  final Duration recordedDuration;

  const VoiceoverState({
    this.status = VoiceoverStatus.idle,
    this.audioPath,
    this.recordedDuration = Duration.zero,
  });

  VoiceoverState copyWith({
    VoiceoverStatus? status,
    String? audioPath,
    Duration? recordedDuration,
  }) {
    return VoiceoverState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      recordedDuration: recordedDuration ?? this.recordedDuration,
    );
  }
}

class VoiceoverNotifier extends StateNotifier<VoiceoverState> {
  VoiceoverNotifier() : super(const VoiceoverState());

  void startRecording() {
    state = state.copyWith(status: VoiceoverStatus.recording);
  }

  void finishRecording(String path, Duration duration) {
    state = VoiceoverState(
      status: VoiceoverStatus.recorded,
      audioPath: path,
      recordedDuration: duration,
    );
  }

  void discard() {
    state = const VoiceoverState();
  }
}
