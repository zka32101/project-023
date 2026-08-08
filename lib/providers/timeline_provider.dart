import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/frame.dart';

final timelineStateProvider = StateNotifierProvider<TimelineStateNotifier, TimelineState>((ref) {
  return TimelineStateNotifier();
});

class TimelineState {
  final List<Frame> frames;
  final int? selectedFrameIndex;
  final bool isPlaying;

  TimelineState({
    this.frames = const [],
    this.selectedFrameIndex,
    this.isPlaying = false,
  });

  TimelineState copyWith({
    List<Frame>? frames,
    int? selectedFrameIndex,
    bool? isPlaying,
  }) {
    return TimelineState(
      frames: frames ?? this.frames,
      selectedFrameIndex: selectedFrameIndex ?? this.selectedFrameIndex,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  double calculateDuration(int fps) {
    if (frames.isEmpty || fps == 0) return 0.0;
    return frames.length / fps;
  }
}

class TimelineStateNotifier extends StateNotifier<TimelineState> {
  TimelineStateNotifier() : super(TimelineState());

  void initializeFrames(List<Frame> frames) {
    state = state.copyWith(frames: frames);
  }

  void addFrame(Frame frame) {
    final updatedFrames = [...state.frames, frame];
    state = state.copyWith(frames: updatedFrames);
  }

  void removeFrame(int index) {
    if (index >= 0 && index < state.frames.length) {
      final updatedFrames = [...state.frames];
      updatedFrames.removeAt(index);
      state = state.copyWith(frames: updatedFrames);
    }
  }

  void reorderFrames(int oldIndex, int newIndex) {
    final frames = [...state.frames];
    final frame = frames.removeAt(oldIndex);
    frames.insert(newIndex, frame);

    // Update order field
    for (int i = 0; i < frames.length; i++) {
      frames[i] = Frame(
        frameId: frames[i].frameId,
        capturedAt: frames[i].capturedAt,
        imageUrl: frames[i].imageUrl,
        characters: frames[i].characters,
        order: i,
      );
    }

    state = state.copyWith(frames: frames);
  }

  void selectFrame(int index) {
    if (index >= 0 && index < state.frames.length) {
      state = TimelineState(
        frames: state.frames,
        selectedFrameIndex: index,
        isPlaying: state.isPlaying,
      );
    }
  }

  void deselectFrame() {
    state = TimelineState(
      frames: state.frames,
      selectedFrameIndex: null,
      isPlaying: state.isPlaying,
    );
  }

  void startPlaying() {
    state = state.copyWith(isPlaying: true);
  }

  void stopPlaying() {
    state = state.copyWith(isPlaying: false);
  }

  void reset() {
    state = TimelineState();
  }
}
