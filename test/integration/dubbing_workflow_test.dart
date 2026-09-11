import 'package:flutter_test/flutter_test.dart';
import 'package:project_023/models/audio_track.dart';
import 'package:project_023/models/dubbing_project.dart';

void main() {
  group('Dubbing Workflow Integration Tests', () {
    late DateTime testTime;

    setUp(() {
      testTime = DateTime.now();
    });

    test('complete workflow: create project, add track, update track', () {
      // Step 1: Create a new project
      final project = DubbingProject(
        id: 'project_workflow_001',
        characterId: 'char_workflow_001',
        projectName: 'Workflow Test Project',
        tracks: [],
        fps: 30,
        totalFrames: 1800,
        createdAt: testTime,
      );

      expect(project.tracks, isEmpty);
      expect(project.id, 'project_workflow_001');

      // Step 2: Create an audio track
      final track = AudioTrack(
        id: 'track_workflow_001',
        name: 'Workflow Test Track',
        audioPath: '/test/audio.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 5000,
      );

      // Step 3: Add track to project (simulated)
      final projectWithTrack = project.copyWith(
        tracks: [...project.tracks, track],
      );

      expect(projectWithTrack.tracks.length, 1);
      expect(projectWithTrack.tracks.first.id, 'track_workflow_001');

      // Step 4: Update track (e.g., adjust volume and mute)
      final updatedTrack = track.copyWith(
        volume: 0.7,
        isMuted: false,
        startFrame: 60,
      );

      final projectWithUpdatedTrack = projectWithTrack.copyWith(
        tracks: [updatedTrack],
      );

      expect(projectWithUpdatedTrack.tracks.first.volume, 0.7);
      expect(projectWithUpdatedTrack.tracks.first.startFrame, 60);
    });

    test('workflow: add multiple tracks to project', () {
      final project = DubbingProject(
        id: 'project_multi_track',
        characterId: 'char_001',
        projectName: 'Multi-Track Project',
        tracks: [],
        fps: 30,
        totalFrames: 2700,
        createdAt: testTime,
      );

      // Add first track
      final track1 = AudioTrack(
        id: 'track_001',
        name: 'Voice 1',
        audioPath: '/audio/voice1.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 5000,
      );

      var projectState = project.copyWith(
        tracks: [...project.tracks, track1],
      );

      expect(projectState.tracks.length, 1);

      // Add second track
      final track2 = AudioTrack(
        id: 'track_002',
        name: 'Voice 2',
        audioPath: '/audio/voice2.wav',
        startFrame: 300,
        volume: 0.8,
        isMuted: false,
        createdAt: testTime,
        duration: 4000,
      );

      projectState = projectState.copyWith(
        tracks: [...projectState.tracks, track2],
      );

      expect(projectState.tracks.length, 2);
      expect(projectState.tracks[0].name, 'Voice 1');
      expect(projectState.tracks[1].name, 'Voice 2');
    });

    test('workflow: remove track from project', () {
      final track1 = AudioTrack(
        id: 'track_001',
        name: 'Keep',
        audioPath: '/audio/keep.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 5000,
      );

      final track2 = AudioTrack(
        id: 'track_002',
        name: 'Remove',
        audioPath: '/audio/remove.wav',
        startFrame: 300,
        volume: 0.8,
        isMuted: false,
        createdAt: testTime,
        duration: 4000,
      );

      final project = DubbingProject(
        id: 'project_removal',
        characterId: 'char_001',
        projectName: 'Removal Test',
        tracks: [track1, track2],
        fps: 30,
        totalFrames: 1800,
        createdAt: testTime,
      );

      expect(project.tracks.length, 2);

      // Remove track2
      final updatedProject = project.copyWith(
        tracks: project.tracks.where((t) => t.id != 'track_002').toList(),
      );

      expect(updatedProject.tracks.length, 1);
      expect(updatedProject.tracks.first.id, 'track_001');
    });

    test('workflow: toggle mute on multiple tracks', () {
      final track1 = AudioTrack(
        id: 'track_001',
        name: 'Track 1',
        audioPath: '/audio/1.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 3000,
      );

      final track2 = AudioTrack(
        id: 'track_002',
        name: 'Track 2',
        audioPath: '/audio/2.wav',
        startFrame: 100,
        volume: 0.8,
        isMuted: false,
        createdAt: testTime,
        duration: 4000,
      );

      var project = DubbingProject(
        id: 'project_mute',
        characterId: 'char_001',
        projectName: 'Mute Test',
        tracks: [track1, track2],
        fps: 30,
        totalFrames: 1800,
        createdAt: testTime,
      );

      // Mute track1
      var track1Updated = track1.copyWith(isMuted: true);
      project = project.copyWith(
        tracks: [track1Updated, track2],
      );

      expect(project.tracks[0].isMuted, true);
      expect(project.tracks[1].isMuted, false);

      // Unmute track1, mute track2
      track1Updated = track1Updated.copyWith(isMuted: false);
      var track2Updated = track2.copyWith(isMuted: true);
      project = project.copyWith(
        tracks: [track1Updated, track2Updated],
      );

      expect(project.tracks[0].isMuted, false);
      expect(project.tracks[1].isMuted, true);
    });

    test('workflow: serialization and deserialization of complete project', () {
      final track = AudioTrack(
        id: 'track_001',
        name: 'Test Track',
        audioPath: '/audio/test.wav',
        startFrame: 50,
        volume: 0.9,
        isMuted: false,
        createdAt: testTime,
        duration: 5500,
      );

      final originalProject = DubbingProject(
        id: 'project_serialize',
        characterId: 'char_001',
        projectName: 'Serialization Test',
        tracks: [track],
        fps: 24,
        totalFrames: 1440,
        createdAt: testTime,
      );

      // Serialize
      final json = originalProject.toJson();

      // Deserialize
      final deserializedProject = DubbingProject.fromJson(json);

      // Verify all data is preserved
      expect(deserializedProject.id, originalProject.id);
      expect(deserializedProject.characterId, originalProject.characterId);
      expect(deserializedProject.projectName, originalProject.projectName);
      expect(deserializedProject.fps, originalProject.fps);
      expect(deserializedProject.totalFrames, originalProject.totalFrames);
      expect(deserializedProject.tracks.length, 1);
      expect(deserializedProject.tracks.first.name, 'Test Track');
      expect(deserializedProject.tracks.first.volume, 0.9);
    });

    test('workflow: adjust timing and volume across multiple tracks', () {
      final track1 = AudioTrack(
        id: 'track_001',
        name: 'Voice',
        audioPath: '/audio/voice.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 5000,
      );

      final track2 = AudioTrack(
        id: 'track_002',
        name: 'BGM',
        audioPath: '/audio/bgm.wav',
        startFrame: 0,
        volume: 1.0,
        isMuted: false,
        createdAt: testTime,
        duration: 6000,
      );

      var project = DubbingProject(
        id: 'project_timing',
        characterId: 'char_001',
        projectName: 'Timing Adjustment Test',
        tracks: [track1, track2],
        fps: 30,
        totalFrames: 1800,
        createdAt: testTime,
      );

      // Adjust voice to start at frame 60
      var updatedVoice = track1.copyWith(startFrame: 60);

      // Reduce BGM volume to 0.6
      var updatedBGM = track2.copyWith(volume: 0.6);

      project = project.copyWith(
        tracks: [updatedVoice, updatedBGM],
      );

      expect(project.tracks[0].startFrame, 60);
      expect(project.tracks[1].volume, 0.6);
    });
  });
}
