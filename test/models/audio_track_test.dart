import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/audio_track.dart';

void main() {
  group('AudioTrack', () {
    final now = DateTime.now();
    final audioTrack = AudioTrack(
      id: 'track_001',
      name: 'Test Track',
      audioPath: '/path/to/audio.wav',
      startFrame: 10,
      volume: 0.8,
      isMuted: false,
      createdAt: now,
      duration: 5000,
    );

    test('creates instance with correct values', () {
      expect(audioTrack.id, 'track_001');
      expect(audioTrack.name, 'Test Track');
      expect(audioTrack.audioPath, '/path/to/audio.wav');
      expect(audioTrack.startFrame, 10);
      expect(audioTrack.volume, 0.8);
      expect(audioTrack.isMuted, false);
      expect(audioTrack.duration, 5000);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = audioTrack.copyWith(
        volume: 0.5,
        isMuted: true,
      );

      expect(updated.id, audioTrack.id);
      expect(updated.name, audioTrack.name);
      expect(updated.volume, 0.5);
      expect(updated.isMuted, true);
      expect(identical(updated, audioTrack), false);
    });

    test('toJson serializes correctly', () {
      final json = audioTrack.toJson();

      expect(json['id'], 'track_001');
      expect(json['name'], 'Test Track');
      expect(json['audioPath'], '/path/to/audio.wav');
      expect(json['startFrame'], 10);
      expect(json['volume'], 0.8);
      expect(json['isMuted'], false);
      expect(json['duration'], 5000);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'track_002',
        'name': 'Another Track',
        'audioPath': '/path/to/audio2.wav',
        'startFrame': 20,
        'volume': 0.6,
        'isMuted': true,
        'createdAt': now.toIso8601String(),
        'duration': 3000,
      };

      final track = AudioTrack.fromJson(json);

      expect(track.id, 'track_002');
      expect(track.name, 'Another Track');
      expect(track.audioPath, '/path/to/audio2.wav');
      expect(track.startFrame, 20);
      expect(track.volume, 0.6);
      expect(track.isMuted, true);
      expect(track.duration, 3000);
    });

    test('equality works correctly', () {
      final track1 = AudioTrack(
        id: 'track_001',
        name: 'Test',
        audioPath: '/path',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: now,
        duration: 1000,
      );

      final track2 = AudioTrack(
        id: 'track_001',
        name: 'Test',
        audioPath: '/path',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: now,
        duration: 1000,
      );

      final track3 = AudioTrack(
        id: 'track_002',
        name: 'Different',
        audioPath: '/other',
        startFrame: 10,
        volume: 0.5,
        isMuted: true,
        createdAt: now,
        duration: 2000,
      );

      expect(track1 == track2, true);
      expect(track1 == track3, false);
    });

    test('hashCode is consistent', () {
      final track = AudioTrack(
        id: 'track_001',
        name: 'Test',
        audioPath: '/path',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: now,
        duration: 1000,
      );

      expect(track.hashCode, track.hashCode);
    });

    test('roundtrip serialization maintains values', () {
      final json = audioTrack.toJson();
      final deserialized = AudioTrack.fromJson(json);

      expect(deserialized.id, audioTrack.id);
      expect(deserialized.name, audioTrack.name);
      expect(deserialized.audioPath, audioTrack.audioPath);
      expect(deserialized.startFrame, audioTrack.startFrame);
      expect(deserialized.volume, audioTrack.volume);
      expect(deserialized.isMuted, audioTrack.isMuted);
      expect(deserialized.duration, audioTrack.duration);
    });
  });
}
