import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/frame.dart';
import '../config/constants.dart';

final cameraStateProvider = StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
  return CameraStateNotifier();
});

class CameraState {
  final bool onionSkinEnabled;
  final int fpsPreset;
  final bool gridGuideEnabled;
  final int frameCount;
  final List<ARCharacterData> placedCharacters;

  CameraState({
    this.onionSkinEnabled = true,
    this.fpsPreset = ARConstants.defaultFPS,
    this.gridGuideEnabled = false,
    this.frameCount = 0,
    this.placedCharacters = const [],
  });

  CameraState copyWith({
    bool? onionSkinEnabled,
    int? fpsPreset,
    bool? gridGuideEnabled,
    int? frameCount,
    List<ARCharacterData>? placedCharacters,
  }) {
    return CameraState(
      onionSkinEnabled: onionSkinEnabled ?? this.onionSkinEnabled,
      fpsPreset: fpsPreset ?? this.fpsPreset,
      gridGuideEnabled: gridGuideEnabled ?? this.gridGuideEnabled,
      frameCount: frameCount ?? this.frameCount,
      placedCharacters: placedCharacters ?? this.placedCharacters,
    );
  }

  bool get isAhaMoment => frameCount >= ARConstants.ahaFrameThreshold;
}

class CameraStateNotifier extends StateNotifier<CameraState> {
  CameraStateNotifier() : super(CameraState());

  void toggleOnionSkin() {
    state = state.copyWith(onionSkinEnabled: !state.onionSkinEnabled);
  }

  void setFpsPreset(int fps) {
    if (fps >= 1 && fps <= 30) {
      state = state.copyWith(fpsPreset: fps);
    }
  }

  void toggleGridGuide() {
    state = state.copyWith(gridGuideEnabled: !state.gridGuideEnabled);
  }

  void placeCharacter(ARCharacterData character) {
    state = state.copyWith(
      placedCharacters: [...state.placedCharacters, character],
    );
  }

  void removeCharacter(int index) {
    final updated = [...state.placedCharacters];
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(placedCharacters: updated);
    }
  }

  void updateCharacter(int index, ARCharacterData character) {
    final updated = [...state.placedCharacters];
    if (index >= 0 && index < updated.length) {
      updated[index] = character;
      state = state.copyWith(placedCharacters: updated);
    }
  }

  void recordFrame() {
    state = state.copyWith(frameCount: state.frameCount + 1);
  }

  void decrementFrameCount() {
    if (state.frameCount > 0) {
      state = state.copyWith(frameCount: state.frameCount - 1);
    }
  }

  void reset() {
    state = CameraState();
  }
}
