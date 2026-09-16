import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/cloud_video.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/cloud_storage_service.dart';

void main() {
  group('CloudStorageService', () {
    late CloudStorageService service;
    late SavedVideo testVideo;

    setUp(() {
      service = CloudStorageService.instance;
      testVideo = SavedVideo(
        id: 'test_video_1',
        projectId: 'test_project',
        filePath: '/test/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
        displayName: 'Test Video',
      );
    });

    test('singleton returns same instance', () {
      final instance1 = CloudStorageService.instance;
      final instance2 = CloudStorageService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('uploadToGoogleDrive creates cloud video', () async {
      final cloudVideo = await service.uploadToGoogleDrive(testVideo);

      expect(cloudVideo.id, isNotEmpty);
      expect(cloudVideo.provider, equals(CloudProvider.googleDrive));
      expect(cloudVideo.status, equals(SyncStatus.synced));
      expect(cloudVideo.localVideoId, equals(testVideo.id));
    });

    test('uploadToICloud creates cloud video', () async {
      final cloudVideo = await service.uploadToICloud(testVideo);

      expect(cloudVideo.id, isNotEmpty);
      expect(cloudVideo.provider, equals(CloudProvider.iCloud));
      expect(cloudVideo.status, equals(SyncStatus.synced));
      expect(cloudVideo.localVideoId, equals(testVideo.id));
    });

    test('uploadToGoogleDrive with makePublic creates public link', () async {
      final cloudVideo =
          await service.uploadToGoogleDrive(testVideo, makePublic: true);

      expect(cloudVideo.publicUrl, isNotNull);
      expect(cloudVideo.publicUrl, contains('drive.google.com'));
    });

    test('uploadToICloud with makePublic creates public link', () async {
      final cloudVideo =
          await service.uploadToICloud(testVideo, makePublic: true);

      expect(cloudVideo.publicUrl, isNotNull);
      expect(cloudVideo.publicUrl, contains('icloud.com'));
    });

    test('getGoogleDriveQuota returns valid quota', () async {
      final quota = await service.getGoogleDriveQuota();

      expect(quota.provider, equals(CloudProvider.googleDrive));
      expect(quota.totalBytes, greaterThan(0));
      expect(quota.freeBytes, greaterThanOrEqualTo(0));
    });

    test('getICloudQuota returns valid quota', () async {
      final quota = await service.getICloudQuota();

      expect(quota.provider, equals(CloudProvider.iCloud));
      expect(quota.totalBytes, greaterThan(0));
      expect(quota.freeBytes, greaterThanOrEqualTo(0));
    });

    test('listCloudVideos returns empty initially', () async {
      final videos = await service.listCloudVideos();

      expect(videos, isEmpty);
    });

    test('listCloudVideos returns uploaded videos', () async {
      await service.uploadToGoogleDrive(testVideo);

      final videos = await service.listCloudVideos();

      expect(videos, isNotEmpty);
      expect(videos.first.localVideoId, equals(testVideo.id));
    });

    test('listCloudVideos filters by provider', () async {
      await service.uploadToGoogleDrive(testVideo);
      await service.uploadToICloud(testVideo);

      final googleVideos =
          await service.listCloudVideos(provider: CloudProvider.googleDrive);
      final iCloudVideos =
          await service.listCloudVideos(provider: CloudProvider.iCloud);

      expect(googleVideos, isNotEmpty);
      expect(iCloudVideos, isNotEmpty);
      expect(googleVideos.first.provider,
          equals(CloudProvider.googleDrive));
      expect(iCloudVideos.first.provider, equals(CloudProvider.iCloud));
    });

    test('listCloudVideos filters by project', () async {
      final video2 = testVideo.copyWith(
        id: 'video2',
        displayName: 'Video 2',
      );
      video2.metadata.createdAt;

      await service.uploadToGoogleDrive(testVideo);
      final videos =
          await service.listCloudVideos(projectId: 'test_project');

      expect(videos, isNotEmpty);
    });

    test('getCloudVideo returns uploaded video', () async {
      final uploaded = await service.uploadToGoogleDrive(testVideo);
      final retrieved = await service.getCloudVideo(uploaded.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(uploaded.id));
    });

    test('getCloudVideo returns null for non-existent video', () async {
      final retrieved = await service.getCloudVideo('nonexistent_id');

      expect(retrieved, isNull);
    });

    test('deleteCloudVideo removes video', () async {
      final uploaded = await service.uploadToGoogleDrive(testVideo);
      final deleted = await service.deleteCloudVideo(uploaded.id);
      final retrieved = await service.getCloudVideo(uploaded.id);

      expect(deleted, isTrue);
      expect(retrieved, isNull);
    });

    test('deleteCloudVideo returns false for non-existent video', () async {
      final deleted = await service.deleteCloudVideo('nonexistent_id');

      expect(deleted, isFalse);
    });

    test('createPublicLink returns URL', () async {
      final uploaded = await service.uploadToGoogleDrive(testVideo);
      final publicUrl = await service.createPublicLink(uploaded.id);

      expect(publicUrl, isNotNull);
      expect(publicUrl, contains('drive.google.com'));
    });

    test('createPublicLink returns null for non-existent video', () async {
      final publicUrl = await service.createPublicLink('nonexistent_id');

      expect(publicUrl, isNull);
    });

    test('getSyncStatistics returns valid stats', () async {
      await service.uploadToGoogleDrive(testVideo);

      final stats = await service.getSyncStatistics();

      expect(stats.totalVideos, equals(1));
      expect(stats.syncedVideos, equals(1));
      expect(stats.totalDataSize, greaterThan(0));
    });

    test('getSyncStatistics counts by provider', () async {
      await service.uploadToGoogleDrive(testVideo);
      await service.uploadToICloud(testVideo);

      final stats = await service.getSyncStatistics();

      expect(stats.googleDriveCount, equals(1));
      expect(stats.iCloudCount, equals(1));
    });

    test('syncAllVideos uploads multiple videos', () async {
      final videos = List.generate(
        3,
        (i) => SavedVideo(
          id: 'video_$i',
          projectId: 'test_project',
          filePath: '/test/path/video_$i.mp4',
          metadata: VideoMetadata(
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            fileSizeBytes: 52428800,
            durationSeconds: 10.0,
            fps: 30,
            format: 'mp4',
          ),
        ),
      );

      final result = await service.syncAllVideos(
        videos,
        provider: CloudProvider.googleDrive,
      );

      expect(result.successful, equals(3));
      expect(result.failed, equals(0));
    });

    test('syncAllVideos respects file size limit', () async {
      final largeVideo = testVideo.copyWith(
        metadata: testVideo.metadata.copyWith(
          fileSizeBytes: 1024 * 1024 * 1024,
        ),
      );

      // Update config to have low limit
      final config = CloudSyncConfig(maxAutoSyncSizeBytes: 100 * 1024 * 1024);
      service.updateSyncConfig(config);

      final result = await service.syncAllVideos([largeVideo]);

      expect(result.failed, greaterThan(0));
    });

    test('updateSyncConfig changes configuration', () {
      final config = CloudSyncConfig(
        autoSync: false,
        wifiOnly: true,
        preferredProvider: CloudProvider.iCloud,
      );

      service.updateSyncConfig(config);
      final currentConfig = service.getSyncConfig();

      expect(currentConfig.autoSync, equals(false));
      expect(currentConfig.wifiOnly, equals(true));
      expect(currentConfig.preferredProvider,
          equals(CloudProvider.iCloud));
    });

    test('getSyncConfig returns current configuration', () {
      final config = service.getSyncConfig();

      expect(config, isA<CloudSyncConfig>());
      expect(config.autoSync, isA<bool>());
    });
  });

  group('SyncResult', () {
    test('getSuccessRate calculates correctly', () {
      final result = SyncResult(
        successful: 8,
        failed: 2,
        errors: [],
        completedAt: DateTime.now(),
      );

      expect(result.getSuccessRate(), closeTo(80.0, 0.1));
    });

    test('getSuccessRate handles zero total', () {
      final result = SyncResult(
        successful: 0,
        failed: 0,
        errors: [],
        completedAt: DateTime.now(),
      );

      expect(result.getSuccessRate(), equals(0.0));
    });

    test('toString returns readable string', () {
      final result = SyncResult(
        successful: 5,
        failed: 1,
        errors: ['Error 1'],
        completedAt: DateTime.now(),
      );

      final str = result.toString();
      expect(str, contains('5'));
      expect(str, contains('6'));
    });
  });

  group('SyncStatistics', () {
    test('getTotalDataSizeString formats bytes correctly', () {
      final stats = SyncStatistics(
        totalVideos: 5,
        syncedVideos: 5,
        syncingVideos: 0,
        failedVideos: 0,
        offlineAvailable: 3,
        totalDataSize: 512 * 1024 * 1024,
        googleDriveCount: 3,
        iCloudCount: 2,
      );

      expect(stats.getTotalDataSizeString(), equals('512.0 MB'));
    });

    test('getTotalDataSizeString handles GB', () {
      final stats = SyncStatistics(
        totalVideos: 10,
        syncedVideos: 10,
        syncingVideos: 0,
        failedVideos: 0,
        offlineAvailable: 5,
        totalDataSize: 2 * 1024 * 1024 * 1024,
        googleDriveCount: 5,
        iCloudCount: 5,
      );

      expect(stats.getTotalDataSizeString(), equals('2.00 GB'));
    });

    test('toString returns readable string', () {
      final stats = SyncStatistics(
        totalVideos: 10,
        syncedVideos: 10,
        syncingVideos: 0,
        failedVideos: 0,
        offlineAvailable: 5,
        totalDataSize: 100 * 1024 * 1024,
        googleDriveCount: 5,
        iCloudCount: 5,
      );

      final str = stats.toString();
      expect(str, contains('10'));
    });
  });

  group('CloudStorageService - Error Handling', () {
    late CloudStorageService service;

    setUp(() {
      service = CloudStorageService.instance;
    });

    test('downloadFromGoogleDrive returns false for non-existent video',
        () async {
      final result = await service.downloadFromGoogleDrive(
        'nonexistent_id',
        '/path/to/dest',
      );

      expect(result, isFalse);
    });

    test('downloadFromICloud returns false for non-existent video', () async {
      final result =
          await service.downloadFromICloud('nonexistent_id', '/path/to/dest');

      expect(result, isFalse);
    });
  });

  group('CloudStorageService - Concurrency', () {
    late CloudStorageService service;
    late SavedVideo testVideo;

    setUp(() {
      service = CloudStorageService.instance;
      testVideo = SavedVideo(
        id: 'test_video_concurrent',
        projectId: 'test_project',
        filePath: '/test/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
      );
    });

    test('multiple concurrent uploads succeed', () async {
      final futures = List.generate(
        5,
        (_) => service.uploadToGoogleDrive(testVideo),
      );

      final results = await Future.wait(futures);

      expect(results, hasLength(5));
      for (final video in results) {
        expect(video.isSynced, isTrue);
      }
    });

    test('quota queries concurrent access', () async {
      final futures = <Future<CloudStorageQuota>>[
        service.getGoogleDriveQuota(),
        service.getGoogleDriveQuota(),
        service.getICloudQuota(),
        service.getICloudQuota(),
      ];

      final results = await Future.wait(futures);

      expect(results, hasLength(4));
      for (final quota in results) {
        expect(quota.totalBytes, greaterThan(0));
      }
    });
  });
}
