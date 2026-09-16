import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/cloud_video.dart';

void main() {
  group('CloudStorageQuota', () {
    test('percentageUsed calculates correctly', () {
      final quota = CloudStorageQuota(
        totalBytes: 1000,
        usedBytes: 250,
        freeBytes: 750,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );

      expect(quota.percentageUsed, closeTo(0.25, 0.01));
    });

    test('isCriticallyLow returns true when free < 100MB', () {
      final quota = CloudStorageQuota(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 1024 * 1024 * 924,
        freeBytes: 100 * 1024 * 1024 - 1,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );

      expect(quota.isCriticallyLow, isTrue);
    });

    test('isLow returns true when free < 500MB', () {
      final quota = CloudStorageQuota(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 1024 * 1024 * 600,
        freeBytes: 424 * 1024 * 1024,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );

      expect(quota.isLow, isTrue);
    });

    test('getUsedString returns correct format', () {
      final quota = CloudStorageQuota(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 512 * 1024 * 1024,
        freeBytes: 512 * 1024 * 1024,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );

      expect(quota.getUsedString(), equals('512.0 MB'));
    });

    test('getFreeString returns correct format', () {
      final quota = CloudStorageQuota(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 512 * 1024 * 1024,
        freeBytes: 512 * 1024 * 1024,
        provider: CloudProvider.iCloud,
        lastUpdated: DateTime.now(),
      );

      expect(quota.getFreeString(), equals('512.0 MB'));
    });

    test('getTotalString returns correct format', () {
      final quota = CloudStorageQuota(
        totalBytes: 512 * 1024 * 1024 * 1024,
        usedBytes: 256 * 1024 * 1024 * 1024,
        freeBytes: 256 * 1024 * 1024 * 1024,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );

      expect(quota.getTotalString(), equals('512.00 GB'));
    });
  });

  group('CloudVideo', () {
    test('isSyncing returns true for syncing status', () {
      final video = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 1024,
        status: SyncStatus.syncing,
        uploadedAt: DateTime.now(),
      );

      expect(video.isSyncing, isTrue);
    });

    test('isSynced returns true for synced status', () {
      final video = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.iCloud,
        fileSizeBytes: 1024,
        status: SyncStatus.synced,
        uploadedAt: DateTime.now(),
      );

      expect(video.isSynced, isTrue);
    });

    test('hasFailed returns true for failed status', () {
      final video = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 1024,
        status: SyncStatus.failed,
        uploadedAt: DateTime.now(),
        errorMessage: 'Upload failed',
      );

      expect(video.hasFailed, isTrue);
    });

    test('getProviderName returns correct name', () {
      final googleDriveVideo = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 1024,
        uploadedAt: DateTime.now(),
      );

      expect(googleDriveVideo.getProviderName(), equals('Google Drive'));

      final iCloudVideo = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.iCloud,
        fileSizeBytes: 1024,
        uploadedAt: DateTime.now(),
      );

      expect(iCloudVideo.getProviderName(), equals('iCloud'));
    });

    test('getStatusLabel returns correct label', () {
      final syncingVideo = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 1024,
        status: SyncStatus.syncing,
        uploadedAt: DateTime.now(),
      );

      expect(syncingVideo.getStatusLabel(), equals('同期中'));
    });

    test('getFileSizeString returns correct format', () {
      final video = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 52 * 1024 * 1024,
        uploadedAt: DateTime.now(),
      );

      expect(video.getFileSizeString(), equals('52.0 MB'));
    });

    test('copyWith creates new instance with modified fields', () {
      final original = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.googleDrive,
        fileSizeBytes: 1024,
        status: SyncStatus.pending,
        uploadedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        status: SyncStatus.synced,
        isAvailableOffline: true,
      );

      expect(modified.status, equals(SyncStatus.synced));
      expect(modified.isAvailableOffline, isTrue);
      expect(modified.id, equals(original.id));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = CloudVideo(
        id: 'test_id',
        cloudFileId: 'cloud_id',
        localVideoId: 'local_id',
        projectId: 'proj_id',
        provider: CloudProvider.iCloud,
        fileSizeBytes: 2048,
        status: SyncStatus.synced,
        uploadedAt: now,
        isAvailableOffline: true,
        publicUrl: 'https://example.com/video',
      );

      final json = original.toJson();
      final restored = CloudVideo.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.provider, equals(original.provider));
      expect(restored.status, equals(original.status));
      expect(restored.isAvailableOffline, equals(original.isAvailableOffline));
      expect(restored.publicUrl, equals(original.publicUrl));
    });
  });

  group('CloudSyncConfig', () {
    test('default config has auto sync enabled', () {
      final config = CloudSyncConfig();

      expect(config.autoSync, isTrue);
    });

    test('default max auto sync size is 500MB', () {
      final config = CloudSyncConfig();

      expect(config.maxAutoSyncSizeBytes, equals(500 * 1024 * 1024));
    });

    test('wifi only can be configured', () {
      final config = CloudSyncConfig(wifiOnly: true);

      expect(config.wifiOnly, isTrue);
    });

    test('public links can be enabled', () {
      final config = CloudSyncConfig(createPublicLinks: true);

      expect(config.createPublicLinks, isTrue);
    });

    test('preferred provider can be set', () {
      final config = CloudSyncConfig(
        preferredProvider: CloudProvider.iCloud,
      );

      expect(config.preferredProvider, equals(CloudProvider.iCloud));
    });

    test('toJson and fromJson work correctly', () {
      final original = CloudSyncConfig(
        autoSync: true,
        wifiOnly: true,
        createPublicLinks: true,
        preferredProvider: CloudProvider.googleDrive,
      );

      final json = original.toJson();
      final restored = CloudSyncConfig.fromJson(json);

      expect(restored.autoSync, equals(original.autoSync));
      expect(restored.wifiOnly, equals(original.wifiOnly));
      expect(restored.createPublicLinks, equals(original.createPublicLinks));
      expect(restored.preferredProvider, equals(original.preferredProvider));
    });
  });

  group('SyncStatus Enum', () {
    test('all sync statuses are defined', () {
      expect(SyncStatus.values, hasLength(5));
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.failed));
      expect(SyncStatus.values, contains(SyncStatus.paused));
    });
  });

  group('CloudProvider Enum', () {
    test('all cloud providers are defined', () {
      expect(CloudProvider.values, hasLength(2));
      expect(CloudProvider.values, contains(CloudProvider.googleDrive));
      expect(CloudProvider.values, contains(CloudProvider.iCloud));
    });
  });
}
