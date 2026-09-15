import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/video_storage_service.dart';

void main() {
  group('VideoMetadata', () {
    test('getFileSizeString returns bytes for small files', () {
      final metadata = VideoMetadata(
        createdAt: DateTime.now(),
        width: 1920,
        height: 1080,
        fileSizeBytes: 512,
        durationSeconds: 5.0,
        fps: 30,
        format: 'mp4',
      );
      expect(metadata.getFileSizeString(), equals('512 B'));
    });

    test('getFileSizeString returns KB for medium files', () {
      final metadata = VideoMetadata(
        createdAt: DateTime.now(),
        width: 1920,
        height: 1080,
        fileSizeBytes: 512 * 1024,
        durationSeconds: 5.0,
        fps: 30,
        format: 'mp4',
      );
      expect(metadata.getFileSizeString(), equals('512.0 KB'));
    });

    test('getFileSizeString returns MB for large files', () {
      final metadata = VideoMetadata(
        createdAt: DateTime.now(),
        width: 1920,
        height: 1080,
        fileSizeBytes: 512 * 1024 * 1024,
        durationSeconds: 5.0,
        fps: 30,
        format: 'mp4',
      );
      expect(metadata.getFileSizeString(), equals('512.0 MB'));
    });

    test('getResolutionString returns correct format', () {
      final metadata = VideoMetadata(
        createdAt: DateTime.now(),
        width: 1920,
        height: 1080,
        fileSizeBytes: 1024,
        durationSeconds: 5.0,
        fps: 30,
        format: 'mp4',
      );
      expect(metadata.getResolutionString(), equals('1920x1080'));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = VideoMetadata(
        createdAt: now,
        width: 1280,
        height: 720,
        fileSizeBytes: 2048,
        durationSeconds: 10.5,
        fps: 24,
        format: 'webm',
      );

      final json = original.toJson();
      final restored = VideoMetadata.fromJson(json);

      expect(restored.width, equals(original.width));
      expect(restored.height, equals(original.height));
      expect(restored.fileSizeBytes, equals(original.fileSizeBytes));
      expect(restored.fps, equals(original.fps));
      expect(restored.format, equals(original.format));
    });
  });

  group('SavedVideo', () {
    test('getDisplayName returns custom name if set', () {
      final video = SavedVideo(
        id: '12345',
        projectId: 'proj1',
        filePath: '/path/to/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 1024,
          durationSeconds: 5.0,
          fps: 30,
          format: 'mp4',
        ),
        displayName: 'My Video',
      );

      expect(video.getDisplayName(), equals('My Video'));
    });

    test('getDisplayName returns ID prefix if not set', () {
      final video = SavedVideo(
        id: '1234567890',
        projectId: 'proj1',
        filePath: '/path/to/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 1024,
          durationSeconds: 5.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      expect(video.getDisplayName(), equals('Video 12345678'));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final metadata = VideoMetadata(
        createdAt: now,
        width: 1920,
        height: 1080,
        fileSizeBytes: 5242880,
        durationSeconds: 15.0,
        fps: 30,
        format: 'mp4',
      );

      final original = SavedVideo(
        id: 'vid123',
        projectId: 'proj456',
        filePath: '/videos/vid123.mp4',
        metadata: metadata,
        displayName: 'Test Video',
      );

      final json = original.toJson();
      final restored = SavedVideo.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.projectId, equals(original.projectId));
      expect(restored.filePath, equals(original.filePath));
      expect(restored.displayName, equals(original.displayName));
    });
  });

  group('StorageInfo', () {
    test('percentageUsed calculates correctly', () {
      final storage = StorageInfo(
        totalBytes: 1000,
        usedBytes: 250,
        freeBytes: 750,
      );

      expect(storage.percentageUsed, closeTo(0.25, 0.01));
    });

    test('isCriticallyLow returns true when free < 100MB', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 1024 * 1024 * 924,
        freeBytes: 100 * 1024 * 1024 - 1,
      );

      expect(storage.isCriticallyLow, isTrue);
    });

    test('isCriticallyLow returns false when free >= 100MB', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 1024 * 1024 * 800,
        freeBytes: 224 * 1024 * 1024,
      );

      expect(storage.isCriticallyLow, isFalse);
    });

    test('isLow returns true when free < 500MB', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 1024 * 1024 * 600,
        freeBytes: 424 * 1024 * 1024,
      );

      expect(storage.isLow, isTrue);
    });

    test('getUsedString returns correct format', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 512 * 1024 * 1024,
        freeBytes: 512 * 1024 * 1024,
      );

      expect(storage.getUsedString(), equals('512.0 MB'));
    });

    test('getFreeString returns correct format', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 512 * 1024 * 1024,
        freeBytes: 512 * 1024 * 1024,
      );

      expect(storage.getFreeString(), equals('512.0 MB'));
    });
  });

  group('VideoStorageService', () {
    late VideoStorageService service;

    setUp(() {
      service = VideoStorageService.instance;
    });

    test('singleton returns same instance', () {
      final instance1 = VideoStorageService.instance;
      final instance2 = VideoStorageService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('getStorageInfo returns valid StorageInfo', () async {
      final storageInfo = await service.getStorageInfo();

      expect(storageInfo.totalBytes, greaterThan(0));
      expect(storageInfo.usedBytes, greaterThanOrEqualTo(0));
      expect(storageInfo.freeBytes, greaterThanOrEqualTo(0));
    });

    test('getStorageInfo free bytes equals total minus used', () async {
      final storageInfo = await service.getStorageInfo();

      expect(
        storageInfo.freeBytes,
        equals(storageInfo.totalBytes - storageInfo.usedBytes),
      );
    });

    test('getProjectVideos returns empty list for non-existent project', () async {
      final videos = await service.getProjectVideos('non_existent_project_123');

      expect(videos, isEmpty);
    });

    test('getAllVideos returns list when called', () async {
      final videos = await service.getAllVideos();

      expect(videos, isA<List<SavedVideo>>());
    });

    test('deleteProjectVideos returns false for non-existent project', () async {
      final result = await service.deleteProjectVideos('non_existent_project_123');

      expect(result, isFalse);
    });

    test('deleteVideo returns false for non-existent video', () async {
      final result =
          await service.deleteVideo('non_existent_video_id', 'proj123');

      expect(result, isFalse);
    });

    test('getVideoMetadata returns null for non-existent file', () async {
      final metadata =
          await service.getVideoMetadata('/non/existent/file.mp4');

      expect(metadata, isNull);
    });

    test('exportVideo returns false for non-existent video', () async {
      final result = await service.exportVideo(
        'non_existent_id',
        'proj123',
        '/export/path.mp4',
      );

      expect(result, isFalse);
    });

    test('searchVideosByDateRange returns empty for future date range',
        () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPlusMinus = tomorrow.add(const Duration(days: 1));

      final videos = await service.searchVideosByDateRange(tomorrow, tomorrowPlusMinus);

      expect(videos, isEmpty);
    });
  });

  group('VideoStorageService - Mock File Operations', () {
    late VideoStorageService service;
    late Directory tempDir;

    setUp(() async {
      service = VideoStorageService.instance;
      tempDir = await Directory.systemTemp.createTemp('video_storage_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveVideo throws exception when source file does not exist',
        () async {
      expect(
        () => service.saveVideo(
          '/non/existent/video.mp4',
          'test_project',
        ),
        throwsException,
      );
    });

    test('saveVideo handles valid inputs', () async {
      // Create a temporary video file
      final tempVideoFile = File('${tempDir.path}/test.mp4');
      await tempVideoFile.writeAsBytes([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

      final savedVideo = await service.saveVideo(
        tempVideoFile.path,
        'test_project',
        displayName: 'Test Video',
        width: 1920,
        height: 1080,
        fps: 30,
        durationSeconds: 5.0,
      );

      expect(savedVideo.id, isNotEmpty);
      expect(savedVideo.projectId, equals('test_project'));
      expect(savedVideo.displayName, equals('Test Video'));
      expect(savedVideo.metadata.width, equals(1920));
      expect(savedVideo.metadata.height, equals(1080));
      expect(savedVideo.metadata.fps, equals(30));
    });
  });
}
