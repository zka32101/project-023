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
      expect(playbackService.currentAudioPath, null);
    });

    test('volume setter accepts valid range', () async {
      final result = await playbackService.setVolume(0.5);
      expect(result, true);
    });

    test('volume setter clamps to valid range', () async {
      final result1 = await playbackService.setVolume(1.5);
      final result2 = await playbackService.setVolume(-0.5);
      expect(result1, true);
      expect(result2, true);
    });

    test('playback rate setter accepts valid values', () async {
      final result = await playbackService.setPlaybackRate(1.5);
      expect(result, true);
    });

    test('playback rate setter clamps to [0.5, 2.0]', () async {
      final result1 = await playbackService.setPlaybackRate(3.0);
      final result2 = await playbackService.setPlaybackRate(0.1);
      expect(result1, true);
      expect(result2, true);
    });

    test('looping can be toggled', () async {
      final result1 = await playbackService.setLooping(true);
      final result2 = await playbackService.setLooping(false);
      expect(result1, true);
      expect(result2, true);
    });

    test('getCurrentPosition returns valid value or null', () async {
      final position = await playbackService.getCurrentPosition();
      expect(position, isA<int?>());
    });

    test('getDuration returns valid value or null', () async {
      final duration = await playbackService.getDuration();
      expect(duration, isA<int?>());
    });
  });
}
