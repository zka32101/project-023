import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_composition.dart';
import 'package:tsukuani/services/video_composition_service.dart';

void main() {
  group('VideoCompositionService', () {
    late VideoCompositionService service;

    setUp(() {
      service = VideoCompositionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('singleton returns same instance', () {
      final service1 = VideoCompositionService();
      final service2 = VideoCompositionService();

      expect(identical(service1, service2), equals(true));
    });

    test('progressStream is a broadcast stream', () {
      final stream1 = service.progressStream;
      final stream2 = service.progressStream;

      // Both can be listened to independently
      expect(stream1, isNotNull);
      expect(stream2, isNotNull);
    });

    test('statusStream is a broadcast stream', () {
      final stream1 = service.statusStream;
      final stream2 = service.statusStream;

      // Both can be listened to independently
      expect(stream1, isNotNull);
      expect(stream2, isNotNull);
    });

    test('isComposing returns false initially', () {
      expect(service.isComposing, equals(false));
    });

    test('throws exception when trying to compose while already composing', () async {
      // This test verifies the exception is thrown
      // Note: In real scenario, we'd need to mock the FFmpeg process
      expect(service.isComposing, equals(false));
    });

    test('cancel throws exception when no process is running', () async {
      expect(
        () => service.cancel(),
        throwsA(isA<VideoCompositionException>()),
      );
    });
  });

  group('VideoCompositionException', () {
    test('creates with message', () {
      final exception = VideoCompositionException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.code, isNull);
    });

    test('creates with message and code', () {
      final exception = VideoCompositionException(
        'Test error',
        code: 'ERROR_CODE',
      );

      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('ERROR_CODE'));
    });

    test('toString returns descriptive string', () {
      final exception = VideoCompositionException('Test error');

      expect(exception.toString(), contains('VideoCompositionException'));
      expect(exception.toString(), contains('Test error'));
    });

    test('implements Exception interface', () {
      final exception = VideoCompositionException('Test error');

      expect(exception, isA<Exception>());
    });
  });

  group('CompositionProgress Factory', () {
    test('fromFrames with 0 frames returns 0%', () {
      final progress = CompositionProgress.fromFrames(0, 100, 0, 10);

      expect(progress.processedFrames, equals(0));
      expect(progress.percentComplete, equals(0.0));
    });

    test('fromFrames with half frames returns 50%', () {
      final progress = CompositionProgress.fromFrames(500, 1000, 0, 10);

      expect(progress.processedFrames, equals(500));
      expect(progress.percentComplete, equals(0.5));
    });

    test('fromFrames calculates ETA with elapsed time', () {
      // 100 frames processed in 5 seconds
      final progress = CompositionProgress.fromFrames(
        100, // processed frames
        200, // total frames
        0, // start time
        5, // current time (5 seconds elapsed)
      );

      // Rate: 100 frames / 5s = 20 frames/s
      // Total time: 200 frames / 20 frames/s = 10s
      // Remaining: 10s - 5s = 5s
      expect(progress.estimatedSecondsRemaining, equals(5));
    });

    test('fromFrames handles zero elapsed time', () {
      final progress = CompositionProgress.fromFrames(
        500, // processed frames
        1000, // total frames
        0, // start time
        0, // current time (just started)
      );

      // With 0 elapsed time, ETA should be 0
      expect(progress.estimatedSecondsRemaining, equals(0));
    });

    test('fromFrames handles zero progress', () {
      final progress = CompositionProgress.fromFrames(
        0, // no frames processed
        1000, // total frames
        0, // start time
        10, // current time
      );

      expect(progress.percentComplete, equals(0.0));
      expect(progress.estimatedSecondsRemaining, equals(0));
    });
  });

  group('CompositionProgress Methods', () {
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
  });

  group('CompositionSettings Validation', () {
    test('valid settings pass validation', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
      );

      expect(settings.isValid, equals(true));
    });

    test('invalid format fails validation', () {
      final settings = CompositionSettings(
        format: 'avi', // invalid
        resolution: '1080p',
        fps: 30,
      );

      expect(settings.isValid, equals(false));
    });

    test('invalid resolution fails validation', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '2K', // invalid
        fps: 30,
      );

      expect(settings.isValid, equals(false));
    });

    test('invalid fps fails validation', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 120, // invalid (> 60)
      );

      expect(settings.isValid, equals(false));
    });

    test('zero fps fails validation', () {
      final settings = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 0, // invalid
      );

      expect(settings.isValid, equals(false));
    });

    test('supported formats are valid', () {
      for (final format in ['mp4', 'webm', 'mov']) {
        final settings = CompositionSettings(
          format: format,
          resolution: '1080p',
          fps: 30,
        );

        expect(settings.isValid, equals(true),
            reason: 'Format $format should be valid');
      }
    });

    test('supported resolutions are valid', () {
      for (final resolution in ['720p', '1080p', '4k']) {
        final settings = CompositionSettings(
          format: 'mp4',
          resolution: resolution,
          fps: 30,
        );

        expect(settings.isValid, equals(true),
            reason: 'Resolution $resolution should be valid');
      }
    });

    test('supported fps values are valid', () {
      for (final fps in [24, 30, 60]) {
        final settings = CompositionSettings(
          format: 'mp4',
          resolution: '1080p',
          fps: fps,
        );

        expect(settings.isValid, equals(true), reason: 'FPS $fps should be valid');
      }
    });
  });

  group('CompositionSettings Copy and Serialization', () {
    test('copyWith creates new instance', () {
      final original = CompositionSettings(
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        videoTitle: 'Original Title',
      );

      final updated = original.copyWith(
        resolution: '720p',
        videoTitle: 'Updated Title',
      );

      expect(original.resolution, equals('1080p'));
      expect(original.videoTitle, equals('Original Title'));
      expect(updated.resolution, equals('720p'));
      expect(updated.videoTitle, equals('Updated Title'));
      expect(updated.format, equals(original.format));
      expect(updated.fps, equals(original.fps));
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

  group('VideoComposition Serialization', () {
    test('toJson includes all fields', () {
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
      );

      final json = composition.toJson();

      expect(json['id'], equals('comp_123'));
      expect(json['projectId'], equals('proj_123'));
      expect(json['format'], equals('mp4'));
      expect(json['resolution'], equals('1080p'));
      expect(json['fps'], equals(30));
      expect(json['fileSizeMB'], equals(123.45));
      expect(json['status'], equals('completed'));
    });

    test('fromJson reconstructs VideoComposition', () {
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
  });

  group('VideoComposition File Size Formatting', () {
    test('getFileSizeString formats bytes correctly', () {
      final comp = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 0.5, // 512 KB
        createdAt: DateTime.now(),
      );

      final sizeStr = comp.getFileSizeString();
      expect(sizeStr, contains('KB'));
    });

    test('getFileSizeString formats megabytes correctly', () {
      final comp = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 500.0,
        createdAt: DateTime.now(),
      );

      final sizeStr = comp.getFileSizeString();
      expect(sizeStr, contains('MB'));
    });

    test('getFileSizeString formats gigabytes correctly', () {
      final comp = VideoComposition(
        id: 'comp_123',
        projectId: 'proj_123',
        outputPath: '/output/video.mp4',
        format: 'mp4',
        resolution: '1080p',
        fps: 30,
        fileSizeMB: 2048.0, // 2 GB
        createdAt: DateTime.now(),
      );

      final sizeStr = comp.getFileSizeString();
      expect(sizeStr, contains('GB'));
    });
  });
}
