import 'package:flutter_test/flutter_test.dart';
import 'package:project_023/services/audio_playback_service.dart';

void main() {
  group('AudioPlaybackService', () {
    late AudioPlaybackService playbackService;

    setUp(() {
      playbackService = AudioPlaybackService();
    });

    tearDown(() async {
      await playbackService.dispose();
    });

    test('singleton returns same instance', () {
      final instance1 = AudioPlaybackService();
      final instance2 = AudioPlaybackService();
      expect(identical(instance1, instance2), true);
    });

    test('initial state is not playing', () {
      expect(playbackService.isPlaying, false);
      expect(playbackService.currentPosition, 0);
    });

    test('volume setter accepts valid range', () async {
      await playbackService.setVolume(0.5);
      expect(playbackService.volume, 0.5);
    });

    test('volume setter clamps to [0.0, 1.0]', () async {
      await playbackService.setVolume(1.5);
      expect(playbackService.volume, 1.0);

      await playbackService.setVolume(-0.5);
      expect(playbackService.volume, 0.0);
    });

    test('playback rate setter accepts valid values', () async {
      await playbackService.setPlaybackRate(1.5);
      expect(playbackService.playbackRate, 1.5);
    });

    test('playback rate setter clamps to [0.5, 2.0]', () async {
      await playbackService.setPlaybackRate(3.0);
      expect(playbackService.playbackRate, 2.0);

      await playbackService.setPlaybackRate(0.1);
      expect(playbackService.playbackRate, 0.5);
    });

    test('looping can be toggled', () async {
      await playbackService.setLooping(true);
      expect(playbackService.isLooping, true);

      await playbackService.setLooping(false);
      expect(playbackService.isLooping, false);
    });
  });
}
