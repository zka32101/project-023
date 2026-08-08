import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioProvider = StateProvider<AudioSelection>((ref) => AudioSelection.none);

enum AudioSelection {
  none,
  upbeat,
  calm,
  exciting,
  jazzy,
}

extension AudioSelectionExt on AudioSelection {
  String get displayName {
    switch (this) {
      case AudioSelection.none:
        return 'BGM なし';
      case AudioSelection.upbeat:
        return '🎵 ポップ';
      case AudioSelection.calm:
        return '🎶 リラックス';
      case AudioSelection.exciting:
        return '⚡ エキサイティング';
      case AudioSelection.jazzy:
        return '🎺 ジャズ';
    }
  }

  String? get assetPath {
    switch (this) {
      case AudioSelection.none:
        return null;
      case AudioSelection.upbeat:
        return 'assets/audio/bgm_upbeat.mp3';
      case AudioSelection.calm:
        return 'assets/audio/bgm_calm.mp3';
      case AudioSelection.exciting:
        return 'assets/audio/bgm_exciting.mp3';
      case AudioSelection.jazzy:
        return 'assets/audio/bgm_jazzy.mp3';
    }
  }
}
