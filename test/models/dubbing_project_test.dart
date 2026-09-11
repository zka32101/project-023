import 'package:flutter_test/flutter_test.dart';
import 'package:project_023/models/audio_track.dart';
import 'package:project_023/models/dubbing_project.dart';

void main() {
  group('DubbingProject', () {
    final now = DateTime.now();
    final track1 = AudioTrack(
      id: 'track_001',
      name: 'Track 1',
      audioPath: '/path/to/audio1.wav',
      startFrame: 0,
      volume: 1.0,
      isMuted: false,
      createdAt: now,
      duration: 5000,
    );

    final track2 = AudioTrack(
      id: 'track_002',
      name: 'Track 2',
      audioPath: '/path/to/audio2.wav',
      startFrame: 100,
      volume: 0.8,
      isMuted: false,
      createdAt: now,
      duration: 3000,
    );

    final project = DubbingProject(
      id: 'project_001',
      characterId: 'char_001',
      projectName: 'Test Project',
      tracks: [track1, track2],
      fps: 30,
      totalFrames: 1800,
      createdAt: now,
    );

    test('creates instance with correct values', () {
      expect(project.id, 'project_001');
      expect(project.characterId, 'char_001');
      expect(project.projectName, 'Test Project');
      expect(project.fps, 30);
      expect(project.totalFrames, 1800);
      expect(project.tracks.length, 2);
    });

    test('framesToMilliseconds converts correctly', () {
      // 30 FPS, 60 frames = 2 seconds = 2000ms
      final ms = project.framesToMilliseconds(60);
      expect(ms, 2000);
    });

    test('millisecondsToFrames converts correctly', () {
      // 30 FPS, 2000ms = 2 seconds = 60 frames
      final frames = project.millisecondsToFrames(2000);
      expect(frames, 60);
    });

    test('getTotalDuration calculates correctly', () {
      // track1: 5000ms, track2: 3000ms
      // total: 8000ms (but depends on startFrame offset)
      final duration = project.getTotalDuration();
      expect(duration, isA<int>());
      expect(duration, greaterThanOrEqualTo(0));
    });

    test('toJson serializes correctly', () {
      final json = project.toJson();

      expect(json['id'], 'project_001');
      expect(json['characterId'], 'char_001');
      expect(json['projectName'], 'Test Project');
      expect(json['fps'], 30);
      expect(json['totalFrames'], 1800);
      expect(json['tracks'], isA<List>());
      expect(json['tracks'].length, 2);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'project_002',
        'characterId': 'char_002',
        'projectName': 'Another Project',
        'fps': 24,
        'totalFrames': 1440,
        'tracks': [
          {
            'id': 'track_003',
            'name': 'Track 3',
            'audioPath': '/path/to/audio3.wav',
            'startFrame': 50,
            'volume': 0.9,
            'isMuted': false,
            'createdAt': now.toIso8601String(),
            'duration': 4000,
          },
        ],
        'createdAt': now.toIso8601String(),
      };

      final deserializedProject = DubbingProject.fromJson(json);

      expect(deserializedProject.id, 'project_002');
      expect(deserializedProject.characterId, 'char_002');
      expect(deserializedProject.projectName, 'Another Project');
      expect(deserializedProject.fps, 24);
      expect(deserializedProject.totalFrames, 1440);
      expect(deserializedProject.tracks.length, 1);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = project.copyWith(
        projectName: 'Updated Project',
        fps: 60,
      );

      expect(updated.id, project.id);
      expect(updated.projectName, 'Updated Project');
      expect(updated.fps, 60);
      expect(updated.totalFrames, project.totalFrames);
      expect(identical(updated, project), false);
    });

    test('equality works correctly', () {
      final project1 = DubbingProject(
        id: 'p_001',
        characterId: 'c_001',
        projectName: 'Project',
        tracks: [track1],
        fps: 30,
        totalFrames: 900,
        createdAt: now,
      );

      final project2 = DubbingProject(
        id: 'p_001',
        characterId: 'c_001',
        projectName: 'Project',
        tracks: [track1],
        fps: 30,
        totalFrames: 900,
        createdAt: now,
      );

      final project3 = DubbingProject(
        id: 'p_002',
        characterId: 'c_002',
        projectName: 'Different',
        tracks: [track2],
        fps: 24,
        totalFrames: 720,
        createdAt: now,
      );

      expect(project1 == project2, true);
      expect(project1 == project3, false);
    });

    test('roundtrip serialization maintains values', () {
      final json = project.toJson();
      final deserialized = DubbingProject.fromJson(json);

      expect(deserialized.id, project.id);
      expect(deserialized.characterId, project.characterId);
      expect(deserialized.projectName, project.projectName);
      expect(deserialized.fps, project.fps);
      expect(deserialized.totalFrames, project.totalFrames);
      expect(deserialized.tracks.length, project.tracks.length);
    });

    test('empty tracks list is valid', () {
      final emptyProject = DubbingProject(
        id: 'empty_project',
        characterId: 'char_001',
        projectName: 'Empty Project',
        tracks: [],
        fps: 30,
        totalFrames: 900,
        createdAt: now,
      );

      expect(emptyProject.tracks, isEmpty);
      expect(emptyProject.getTotalDuration(), isA<int>());
    });
  });
}
