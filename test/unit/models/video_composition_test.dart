import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_composition.dart';

void main() {
  group('CompositionStatus enum', () {
    test('has correct values', () {
      expect(CompositionStatus.pending.name, equals('pending'));
      expect(CompositionStatus.processing.name, equals('processing'));
      expect(CompositionStatus.completed.name, equals('completed'));
      expect(CompositionStatus.failed.name, equals('failed'));
    });
  });

  group('CompositionProgress', () {
    test('creates with correct values', () {
      final progress = CompositionProgress(
        processedFrames: 100,
        totalFrames: 1000,
        percentComplete: 0.1,
        estimatedSecondsRemaining: 900,
      );

      expect(progress.processedFrames, equals(100));
      expect(progress.totalFrames, equals(1000));
      expect(progress.percentComplete, equals(0.1));
      expect(progress.estimatedSecondsRemaining, equals(900));
    });

    test('isComplete returns true at 100%', () {
      final progress = CompositionProgress(
        processedFrames: 1000,
        totalFrames: 1000,
        percentComplete: 1.0,
        estimatedSecondsRemaining: 0,
      );

      expect(progress.isComplete, equals(true));
    });

    test('isComplete returns false below 100%', () {
      final progress = CompositionProgress(
        processedFrames: 500,
        totalFrames: 1000,
        percentComplete: 0.5,
        estimatedSecondsRemaining: 500,
      );

      expect(progress.isComplete, equals(false));
    });

    test('getProgressString formats correctly', () {
      final progress = CompositionProgress(
        processedFrames: 250,
        totalFrames: 1000,
        percentComplete: 0.25,
        estimatedSecondsRemaining: 750,
      );

      final str = progress.getProgressString();
      expect(str, contains('250'));
      expect(str, contains('1000'));
      expect(str, contains('25.0%'));
    });

    test('fromFrames calculates correct percentage', () {
      final progress = CompositionProgress.fromFrames(
        500, // processed frames
        1000, // total frames
        0, // start time in seconds
        10, // current time in seconds
      );

      expect(progress.processedFrames, equals(500));
      expect(progress.totalFrames, equals(1000));
      expect(progress.percentComplete, equals(0.5));
    });

    test('fromFrames calculates ETA correctly', () {
      final progress = CompositionProgress.fromFrames(
        500, // processed frames in 10 seconds
        1000, // total frames
        0, // start time
        10, // current time (10 seconds elapsed)
      );

      // 500 frames in 10s = 50 frames/s
      // 1000 frames total = 20s total time
      // 20s - 10s = 10s remaining
      expect(progress.estimatedSecondsRemaining, equals(10));
    });

    test('fromFrames clamps percentage between 0 and 1', () {
      final progress = CompositionProgress.fromFrames(
        2000, // more than total
        1000,
        0,
        10,
      );

      expect(progress.percentComplete, greaterThanOrEqualTo(0.0));
      expect(progress.percentComplete, lessThanOrEqualTo(1.0));
    });

    test('toString returns descriptive string', () {
      final progress = CompositionProgress(
        processedFrames: 250,
        totalFrames: 1000,
        percentComplete: 0.25,
        estimatedSecondsRemaining: 750,
      );

      final str = progress.toString();
      expect(str, contains('CompositionProgress'));
      expect(str, contains('250/1000'));
      expect(str, contains('25.0%'));
    });
  });

  group('VideoComposition', () {
    test('creates with all parameters', () {
      final now = DateTime.now();
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 123.45,
        createdAt: now,
        status: CompositionStatus.completed,
        errorMessage: null,
      );

      expect(composition.id, equals('comp_123'));
      expect(composition.projectId, equals('proj_123'));
      expect(composition.format, equals('mp4'));
      expect(composition.resolution, equals('1080p'));
      expect(composition.fps, equals(30));
      expect(composition.fileSizeMB, equals(123.45));
      expect(composition.status, equals(CompositionStatus.completed));
    });

    test('isSuccess returns true when completed', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: DateTime.now(),
        status: CompositionStatus.completed,
      );

      expect(composition.isSuccess, equals(true));
    });

    test('isSuccess returns false when not completed', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: DateTime.now(),
        status: CompositionStatus.processing,
      );

      expect(composition.isSuccess, equals(false));
    });

    test('isProcessing returns true when processing', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: DateTime.now(),
        status: CompositionStatus.processing,
      );

      expect(composition.isProcessing, equals(true));
    });

    test('hasFailed returns true when failed', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: DateTime.now(),
        status: CompositionStatus.failed,
        errorMessage: 'FFmpeg error',
      );

      expect(composition.hasFailed, equals(true));
    });

    test('getFileSizeString formats KB correctly', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 0.5, // 512 KB
        createdAt: DateTime.now(),
      );

      final sizeStr = composition.getFileSizeString();
      expect(sizeStr, contains('KB'));
    });

    test('getFileSizeString formats MB correctly', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 500.0,
        createdAt: DateTime.now(),
      );

      final sizeStr = composition.getFileSizeString();
      expect(sizeStr, contains('MB'));
    });

    test('getFileSizeString formats GB correctly', () {
      final composition = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 2048.0, // 2 GB
        createdAt: DateTime.now(),
      );

      final sizeStr = composition.getFileSizeString();
      expect(sizeStr, contains('GB'));
    });

    test('getStatusLabel returns Japanese status', () {
      expect(
        VideoComposition(
          id: 'comp_123',
          projectId: 'proj_123',
          outputPath: '/output/video.mp4',
          format: 'mp4',
          resolution: '1080p',
          fps: 30,
          fileSizeMB: 100,
          createdAt: DateTime.now(),
          status: CompositionStatus.pending,
        ).getStatusLabel(),
        equals('待機中'),
      );

      expect(
        VideoComposition(
          id: 'comp_123',
          projectId: 'proj_123',
          outputPath: '/output/video.mp4',
          format: 'mp4',
          resolution: '1080p',
          fps: 30,
          fileSizeMB: 100,
          createdAt: DateTime.now(),
          status: CompositionStatus.completed,
        ).getStatusLabel(),
        equals('完了'),
      );
    });

    test('copyWith creates new instance with modified fields', () {
      final original = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: DateTime.now(),
        status: CompositionStatus.processing,
      );

      final updated = original.copyWith(
        status: CompositionStatus.completed,
      );

      expect(original.status, equals(CompositionStatus.processing));
      expect(updated.status, equals(CompositionStatus.completed));
      expect(updated.id, equals(original.id));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 123.45,
        createdAt: now,
        status: CompositionStatus.completed,
      );

      final json = original.toJson();
      final restored = VideoComposition.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.projectId, equals(original.projectId));
      expect(restored.format, equals(original.format));
      expect(restored.resolution, equals(original.resolution));
      expect(restored.fps, equals(original.fps));
      expect(restored.fileSizeMB, equals(original.fileSizeMB));
      expect(restored.status, equals(original.status));
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final comp1 = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: now,
      );

      final comp2 = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: now,
      );

      expect(comp1, equals(comp2));
    });

    test('hashCode is consistent', () {
      final now = DateTime.now();
      final comp = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 100,
        createdAt: now,
      );

      expect(comp.hashCode, equals(comp.hashCode));
    });
  });

  group('CompositionSettings', () {
    test('creates with required parameters', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
      );

      expect(settings.format, equals('mp4'));
      expect(settings.resolution, equals('1080p'));
      expect(settings.fps, equals(30));
      expect(settings.videoBitrate, equals('3000k'));
      expect(settings.audioBitrate, equals('128k'));
      expect(settings.normalizeAudio, equals(true));
    });

    test('isValid returns true for valid settings', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
      );

      expect(settings.isValid, equals(true));
    });

    test('isValid returns false for invalid format', () {
      final settings = CompositionSettings(
        format: 'avi',
        resolution: '1080p',
        fps: 30,
      );

      expect(settings.isValid, equals(false));
    });

    test('isValid returns false for invalid resolution', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '2K',
        fps: 30,
      );

      expect(settings.isValid, equals(false));
    });

    test('isValid returns false for invalid fps', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 120,
      );

      expect(settings.isValid, equals(false));
    });

    test('getResolutionLabel returns correct dimensions', () {
      expect(
        CompositionSettings(
          format: 'mp4',
          resolution: '720p',
          fps: 30,
        ).getResolutionLabel(),
        equals('1280x720'),
      );

      expect(
        CompositionSettings(
          format: 'mp4',
          resolution: '1080p',
          fps: 30,
        ).getResolutionLabel(),
        equals('1920x1080'),
      );

      expect(
        CompositionSettings(
          format: 'mp4',
          resolution: '4k',
          fps: 30,
        ).getResolutionLabel(),
        equals('3840x2160'),
      );
    });

    test('copyWith creates new instance with modified fields', () {
      final original = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
      );

      final updated = original.copyWith(
        resolution: '720p',
      );

      expect(original.resolution, equals('1080p'));
      expect(updated.resolution, equals('720p'));
      expect(updated.format, equals(original.format));
    });

    test('toString returns descriptive string', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
      );

      final str = settings.toString();
      expect(str, contains('CompositionSettings'));
      expect(str, contains('mp4'));
      expect(str, contains('1080p'));
      expect(str, contains('30fps'));
    });
  });
}
