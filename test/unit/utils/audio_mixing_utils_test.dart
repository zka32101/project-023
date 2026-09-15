import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/utils/audio_mixing_utils.dart';

void main() {
  group('AudioMixingConfig', () {
    test('creates with default values', () {
      final config = AudioMixingConfig();

      expect(config.trackVolumes, isEmpty);
      expect(config.outputVolume, equals(1.0));
      expect(config.normalize, equals(true));
      expect(config.sampleRate, equals(48000));
    });

    test('creates with custom values', () {
      final volumes = [0.8, 0.6, 0.4];
      final config = AudioMixingConfig(
        trackVolumes: volumes,
        outputVolume: 0.9,
        normalize: false,
        sampleRate: 44100,
      );

      expect(config.trackVolumes, equals(volumes));
      expect(config.outputVolume, equals(0.9));
      expect(config.normalize, equals(false));
      expect(config.sampleRate, equals(44100));
    });

    test('isValid returns true for valid config', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 0.5],
        outputVolume: 0.8,
        sampleRate: 48000,
      );

      expect(config.isValid, equals(true));
    });

    test('isValid returns false for invalid track volumes', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 1.5], // Invalid: > 1.0
        outputVolume: 0.8,
      );

      expect(config.isValid, equals(false));
    });

    test('isValid returns false for invalid output volume', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 0.5],
        outputVolume: 1.5, // Invalid: > 1.0
      );

      expect(config.isValid, equals(false));
    });

    test('isValid returns false for invalid sample rate', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 0.5],
        outputVolume: 0.8,
        sampleRate: 96000, // Invalid: not 44100 or 48000
      );

      expect(config.isValid, equals(false));
    });

    test('getFilterString returns empty for zero tracks', () {
      final config = AudioMixingConfig();
      expect(config.getFilterString(0), equals(''));
    });

    test('getFilterString handles single track', () {
      final config = AudioMixingConfig(trackVolumes: [0.8]);
      final filter = config.getFilterString(1);

      expect(filter, contains('volume=0.8'));
      expect(filter, contains('[a]'));
    });

    test('getFilterString handles multiple tracks without volume', () {
      final config = AudioMixingConfig(trackVolumes: []);
      final filter = config.getFilterString(2);

      expect(filter, contains('amix'));
      expect(filter, contains('inputs=2'));
    });

    test('getFilterString handles multiple tracks with volumes', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.8, 0.6],
      );
      final filter = config.getFilterString(2);

      expect(filter, contains('volume=0.8'));
      expect(filter, contains('volume=0.6'));
      expect(filter, contains('amix'));
      expect(filter, contains('inputs=2'));
    });

    test('getFilterString applies output volume', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 0.5],
        outputVolume: 0.8,
      );
      final filter = config.getFilterString(2);

      expect(filter, contains('volume=0.8'));
    });

    test('calculateNormalizationFactor returns 1.0 for safe volume', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.3, 0.3],
        outputVolume: 1.0,
      );

      expect(config.calculateNormalizationFactor(), equals(1.0));
    });

    test('calculateNormalizationFactor scales down for loud volume', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.8, 0.8],
        outputVolume: 1.0,
      );
      final factor = config.calculateNormalizationFactor();

      expect(factor, lessThan(1.0));
      expect(factor, greaterThan(0.0));
    });

    test('toString returns descriptive string', () {
      final config = AudioMixingConfig(
        trackVolumes: [0.5, 0.5],
        outputVolume: 0.8,
        sampleRate: 48000,
      );

      final str = config.toString();
      expect(str, contains('AudioMixingConfig'));
      expect(str, contains('tracks: 2'));
      expect(str, contains('output: 0.8'));
    });
  });

  group('AudioTrackInfo', () {
    test('creates with all parameters', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Narration',
        filePath: '/path/narration.mp3',
        volume: 0.8,
        isMuted: false,
        startMs: 0,
        durationMs: 10000,
      );

      expect(track.id, equals('track_1'));
      expect(track.name, equals('Narration'));
      expect(track.filePath, equals('/path/narration.mp3'));
      expect(track.volume, equals(0.8));
      expect(track.isMuted, equals(false));
      expect(track.startMs, equals(0));
      expect(track.durationMs, equals(10000));
    });

    test('creates with default values', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '/path/audio.mp3',
      );

      expect(track.volume, equals(1.0));
      expect(track.isMuted, equals(false));
      expect(track.startMs, equals(0));
      expect(track.durationMs, equals(0));
    });

    test('effectiveVolume returns 0 when muted', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '/path/audio.mp3',
        volume: 0.8,
        isMuted: true,
      );

      expect(track.effectiveVolume, equals(0.0));
    });

    test('effectiveVolume returns volume when not muted', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '/path/audio.mp3',
        volume: 0.8,
        isMuted: false,
      );

      expect(track.effectiveVolume, equals(0.8));
    });

    test('isValid returns true with id and filePath', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '/path/audio.mp3',
      );

      expect(track.isValid, equals(true));
    });

    test('isValid returns false with empty id', () {
      final track = AudioTrackInfo(
        id: '',
        name: 'Track',
        filePath: '/path/audio.mp3',
      );

      expect(track.isValid, equals(false));
    });

    test('isValid returns false with empty filePath', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '',
      );

      expect(track.isValid, equals(false));
    });

    test('toString returns descriptive string', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Narration',
        filePath: '/path/narration.mp3',
        volume: 0.8,
        isMuted: false,
      );

      final str = track.toString();
      expect(str, contains('AudioTrackInfo'));
      expect(str, contains('track_1'));
      expect(str, contains('Narration'));
      expect(str, contains('volume: 0.8'));
    });
  });

  group('AudioMixingUtils', () {
    test('generateAudioFilterChain returns empty for no tracks', () {
      final filter = AudioMixingUtils.generateAudioFilterChain([]);
      expect(filter, equals(''));
    });

    test('generateAudioFilterChain handles single track', () {
      final track = AudioTrackInfo(
        id: 'track_1',
        name: 'Track',
        filePath: '/path/audio.mp3',
        volume: 0.8,
      );

      final filter = AudioMixingUtils.generateAudioFilterChain([track]);
      expect(filter, contains('volume=0.8'));
      expect(filter, contains('[0:a]'));
    });

    test('generateAudioFilterChain handles multiple tracks', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          volume: 0.8,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          volume: 0.6,
        ),
      ];

      final filter = AudioMixingUtils.generateAudioFilterChain(tracks);
      expect(filter, contains('amix'));
      expect(filter, contains('volume=0.8'));
      expect(filter, contains('volume=0.6'));
    });

    test('calculateTotalDuration returns max end time', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          startMs: 0,
          durationMs: 5000,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          startMs: 2000,
          durationMs: 6000,
        ),
      ];

      final duration = AudioMixingUtils.calculateTotalDuration(tracks);
      expect(duration, equals(8000)); // 2000 + 6000
    });

    test('calculateTotalDuration returns 0 for empty tracks', () {
      final duration = AudioMixingUtils.calculateTotalDuration([]);
      expect(duration, equals(0));
    });

    test('hasOverlappingTracks detects no overlap', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          startMs: 0,
          durationMs: 2000,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          startMs: 2000,
          durationMs: 2000,
        ),
      ];

      expect(AudioMixingUtils.hasOverlappingTracks(tracks), equals(false));
    });

    test('hasOverlappingTracks detects overlap', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          startMs: 0,
          durationMs: 3000,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          startMs: 2000,
          durationMs: 2000,
        ),
      ];

      expect(AudioMixingUtils.hasOverlappingTracks(tracks), equals(true));
    });

    test('validateTracks returns null for valid tracks', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          volume: 0.8,
        ),
      ];

      final error = AudioMixingUtils.validateTracks(tracks);
      expect(error, isNull);
    });

    test('validateTracks returns error for empty list', () {
      final error = AudioMixingUtils.validateTracks([]);
      expect(error, isNotNull);
      expect(error, contains('At least one'));
    });

    test('validateTracks returns error for invalid track', () {
      final tracks = [
        AudioTrackInfo(
          id: '',
          name: 'Track',
          filePath: '/path/audio.mp3',
        ),
      ];

      final error = AudioMixingUtils.validateTracks(tracks);
      expect(error, isNotNull);
      expect(error, contains('invalid'));
    });

    test('validateTracks returns error for invalid volume', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track',
          filePath: '/path/audio.mp3',
          volume: 1.5, // Invalid
        ),
      ];

      final error = AudioMixingUtils.validateTracks(tracks);
      expect(error, isNotNull);
      expect(error, contains('volume'));
    });

    test('calculateSafeVolume returns 1.0 for low combined volume', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          volume: 0.3,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          volume: 0.3,
        ),
      ];

      final safeVolume = AudioMixingUtils.calculateSafeVolume(tracks);
      expect(safeVolume, equals(1.0));
    });

    test('calculateSafeVolume scales down for loud combined volume', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          volume: 0.8,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          volume: 0.8,
        ),
      ];

      final safeVolume = AudioMixingUtils.calculateSafeVolume(tracks);
      expect(safeVolume, lessThan(1.0));
      expect(safeVolume, greaterThan(0.0));
    });

    test('calculateSafeVolume ignores muted tracks', () {
      final tracks = [
        AudioTrackInfo(
          id: 'track_1',
          name: 'Track 1',
          filePath: '/path/audio1.mp3',
          volume: 0.8,
          isMuted: true,
        ),
        AudioTrackInfo(
          id: 'track_2',
          name: 'Track 2',
          filePath: '/path/audio2.mp3',
          volume: 0.2,
          isMuted: false,
        ),
      ];

      final safeVolume = AudioMixingUtils.calculateSafeVolume(tracks);
      expect(safeVolume, equals(1.0)); // Only counts unmuted track
    });

    test('getRecommendedBitrate returns correct values', () {
      expect(AudioMixingUtils.getRecommendedBitrate(0), equals('0k'));
      expect(AudioMixingUtils.getRecommendedBitrate(1), equals('128k'));
      expect(AudioMixingUtils.getRecommendedBitrate(2), equals('160k'));
      expect(AudioMixingUtils.getRecommendedBitrate(3), equals('192k'));
      expect(AudioMixingUtils.getRecommendedBitrate(4), equals('256k'));
      expect(AudioMixingUtils.getRecommendedBitrate(10), equals('256k'));
    });
  });
}
