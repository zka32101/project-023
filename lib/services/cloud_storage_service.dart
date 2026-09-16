/// Cloud storage service for managing video uploads to Google Drive and iCloud

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tsukuani/models/cloud_video.dart';
import 'package:tsukuani/models/video_storage_models.dart';

/// Service for managing cloud storage operations
class CloudStorageService {
  static CloudStorageService? _instance;

  /// Cloud sync configuration
  CloudSyncConfig _config = CloudSyncConfig();

  /// Map of synced videos
  final Map<String, CloudVideo> _syncedVideos = {};

  /// Singleton instance
  static CloudStorageService get instance {
    _instance ??= CloudStorageService._();
    return _instance;
  }

  CloudStorageService._();

  /// Update sync configuration
  void updateSyncConfig(CloudSyncConfig config) {
    _config = config;
  }

  /// Get current sync configuration
  CloudSyncConfig getSyncConfig() => _config;

  /// Upload video to Google Drive
  Future<CloudVideo> uploadToGoogleDrive(
    SavedVideo video, {
    bool makePublic = false,
  }) async {
    try {
      final cloudVideoId = _generateId();
      final now = DateTime.now();

      // Simulate upload to Google Drive
      // In production, this would use google_sign_in and googleapis packages
      await Future.delayed(const Duration(milliseconds: 500));

      final cloudVideo = CloudVideo(
        id: cloudVideoId,
        cloudFileId: 'gd_$cloudVideoId',
        localVideoId: video.id,
        projectId: video.projectId,
        provider: CloudProvider.googleDrive,
        fileSizeBytes: video.metadata.fileSizeBytes,
        status: SyncStatus.synced,
        uploadedAt: now,
        lastSyncedAt: now,
        isAvailableOffline: false,
        publicUrl: makePublic ? 'https://drive.google.com/file/d/$cloudVideoId'
            : null,
      );

      _syncedVideos[cloudVideoId] = cloudVideo;
      return cloudVideo;
    } catch (e) {
      throw Exception('Failed to upload to Google Drive: $e');
    }
  }

  /// Upload video to iCloud
  Future<CloudVideo> uploadToICloud(
    SavedVideo video, {
    bool makePublic = false,
  }) async {
    try {
      final cloudVideoId = _generateId();
      final now = DateTime.now();

      // Simulate upload to iCloud
      // In production, this would use CloudKit framework
      await Future.delayed(const Duration(milliseconds: 500));

      final cloudVideo = CloudVideo(
        id: cloudVideoId,
        cloudFileId: 'ic_$cloudVideoId',
        localVideoId: video.id,
        projectId: video.projectId,
        provider: CloudProvider.iCloud,
        fileSizeBytes: video.metadata.fileSizeBytes,
        status: SyncStatus.synced,
        uploadedAt: now,
        lastSyncedAt: now,
        isAvailableOffline: false,
        publicUrl: makePublic ? 'https://icloud.com/share/$cloudVideoId'
            : null,
      );

      _syncedVideos[cloudVideoId] = cloudVideo;
      return cloudVideo;
    } catch (e) {
      throw Exception('Failed to upload to iCloud: $e');
    }
  }

  /// Download video from Google Drive
  Future<bool> downloadFromGoogleDrive(
    String cloudVideoId,
    String destinationPath,
  ) async {
    try {
      if (!_syncedVideos.containsKey(cloudVideoId)) {
        return false;
      }

      // Simulate download from Google Drive
      await Future.delayed(const Duration(milliseconds: 500));

      // Create destination file
      final file = File(destinationPath);
      await file.create(recursive: true);
      await file.writeAsString('[Video Data from Google Drive]');

      // Update sync status
      final cloudVideo = _syncedVideos[cloudVideoId]!;
      _syncedVideos[cloudVideoId] = cloudVideo.copyWith(
        lastSyncedAt: DateTime.now(),
        isAvailableOffline: true,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download video from iCloud
  Future<bool> downloadFromICloud(
    String cloudVideoId,
    String destinationPath,
  ) async {
    try {
      if (!_syncedVideos.containsKey(cloudVideoId)) {
        return false;
      }

      // Simulate download from iCloud
      await Future.delayed(const Duration(milliseconds: 500));

      // Create destination file
      final file = File(destinationPath);
      await file.create(recursive: true);
      await file.writeAsString('[Video Data from iCloud]');

      // Update sync status
      final cloudVideo = _syncedVideos[cloudVideoId]!;
      _syncedVideos[cloudVideoId] = cloudVideo.copyWith(
        lastSyncedAt: DateTime.now(),
        isAvailableOffline: true,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage quota for Google Drive
  Future<CloudStorageQuota> getGoogleDriveQuota() async {
    try {
      // Simulate fetching quota from Google Drive API
      await Future.delayed(const Duration(milliseconds: 300));

      return CloudStorageQuota(
        totalBytes: 15 * 1024 * 1024 * 1024,
        usedBytes: 5 * 1024 * 1024 * 1024,
        freeBytes: 10 * 1024 * 1024 * 1024,
        provider: CloudProvider.googleDrive,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get Google Drive quota: $e');
    }
  }

  /// Get storage quota for iCloud
  Future<CloudStorageQuota> getICloudQuota() async {
    try {
      // Simulate fetching quota from iCloud
      await Future.delayed(const Duration(milliseconds: 300));

      return CloudStorageQuota(
        totalBytes: 5 * 1024 * 1024 * 1024,
        usedBytes: 2 * 1024 * 1024 * 1024,
        freeBytes: 3 * 1024 * 1024 * 1024,
        provider: CloudProvider.iCloud,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get iCloud quota: $e');
    }
  }

  /// List all cloud videos
  Future<List<CloudVideo>> listCloudVideos({
    CloudProvider? provider,
    String? projectId,
  }) async {
    var videos = _syncedVideos.values.toList();

    if (provider != null) {
      videos = videos.where((v) => v.provider == provider).toList();
    }

    if (projectId != null) {
      videos = videos.where((v) => v.projectId == projectId).toList();
    }

    // Sort by upload time (newest first)
    videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return videos;
  }

  /// Get cloud video by ID
  Future<CloudVideo?> getCloudVideo(String cloudVideoId) async {
    return _syncedVideos[cloudVideoId];
  }

  /// Delete cloud video
  Future<bool> deleteCloudVideo(String cloudVideoId) async {
    try {
      if (!_syncedVideos.containsKey(cloudVideoId)) {
        return false;
      }

      final cloudVideo = _syncedVideos[cloudVideoId]!;

      // Simulate delete operation
      await Future.delayed(const Duration(milliseconds: 300));

      _syncedVideos.remove(cloudVideoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sync all videos to cloud
  Future<SyncResult> syncAllVideos(
    List<SavedVideo> videos, {
    CloudProvider? provider,
  }) async {
    final syncProvider = provider ?? _config.preferredProvider ?? CloudProvider.googleDrive;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final video in videos) {
      try {
        // Check file size limit
        if (video.metadata.fileSizeBytes > _config.maxAutoSyncSizeBytes) {
          failed++;
          errors.add('${video.getDisplayName()}: File too large');
          continue;
        }

        // Upload based on provider
        if (syncProvider == CloudProvider.googleDrive) {
          await uploadToGoogleDrive(video);
        } else {
          await uploadToICloud(video);
        }
        successful++;
      } catch (e) {
        failed++;
        errors.add('${video.getDisplayName()}: ${e.toString()}');
      }
    }

    return SyncResult(
      successful: successful,
      failed: failed,
      errors: errors,
      completedAt: DateTime.now(),
    );
  }

  /// Create public link for video
  Future<String?> createPublicLink(String cloudVideoId) async {
    try {
      final cloudVideo = _syncedVideos[cloudVideoId];
      if (cloudVideo == null) {
        return null;
      }

      if (cloudVideo.publicUrl != null) {
        return cloudVideo.publicUrl;
      }

      final publicUrl = switch (cloudVideo.provider) {
        CloudProvider.googleDrive =>
          'https://drive.google.com/file/d/$cloudVideoId/view',
        CloudProvider.iCloud => 'https://icloud.com/share/$cloudVideoId',
      };

      // Update video with public URL
      _syncedVideos[cloudVideoId] = cloudVideo.copyWith(
        publicUrl: publicUrl,
      );

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Get synced video statistics
  Future<SyncStatistics> getSyncStatistics({
    String? projectId,
  }) async {
    var videos = _syncedVideos.values.toList();

    if (projectId != null) {
      videos = videos.where((v) => v.projectId == projectId).toList();
    }

    int synced = videos.where((v) => v.isSynced).length;
    int syncing = videos.where((v) => v.isSyncing).length;
    int failed = videos.where((v) => v.hasFailed).length;
    int offline = videos.where((v) => v.isAvailableOffline).length;

    int totalSize = 0;
    for (final video in videos) {
      totalSize += video.fileSizeBytes;
    }

    return SyncStatistics(
      totalVideos: videos.length,
      syncedVideos: synced,
      syncingVideos: syncing,
      failedVideos: failed,
      offlineAvailable: offline,
      totalDataSize: totalSize,
      googleDriveCount: videos.where((v) => v.provider == CloudProvider.googleDrive).length,
      iCloudCount: videos.where((v) => v.provider == CloudProvider.iCloud).length,
    );
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Result of sync operation
class SyncResult {
  /// Number of successfully synced videos
  final int successful;

  /// Number of failed sync operations
  final int failed;

  /// Error messages
  final List<String> errors;

  /// Completion timestamp
  final DateTime completedAt;

  SyncResult({
    required this.successful,
    required this.failed,
    required this.errors,
    required this.completedAt,
  });

  /// Get success rate percentage
  double getSuccessRate() {
    final total = successful + failed;
    return total > 0 ? (successful / total) * 100 : 0.0;
  }

  @override
  String toString() =>
      'SyncResult(${successful}/${successful + failed} successful, ${errors.length} errors)';
}

/// Statistics about synced videos
class SyncStatistics {
  /// Total number of synced videos
  final int totalVideos;

  /// Number of successfully synced videos
  final int syncedVideos;

  /// Number of videos currently syncing
  final int syncingVideos;

  /// Number of failed sync operations
  final int failedVideos;

  /// Number of videos available offline
  final int offlineAvailable;

  /// Total data size of synced videos (in bytes)
  final int totalDataSize;

  /// Number of videos on Google Drive
  final int googleDriveCount;

  /// Number of videos on iCloud
  final int iCloudCount;

  SyncStatistics({
    required this.totalVideos,
    required this.syncedVideos,
    required this.syncingVideos,
    required this.failedVideos,
    required this.offlineAvailable,
    required this.totalDataSize,
    required this.googleDriveCount,
    required this.iCloudCount,
  });

  /// Get total data size as human-readable string
  String getTotalDataSizeString() {
    if (totalDataSize < 1024 * 1024) {
      final kb = totalDataSize / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (totalDataSize < 1024 * 1024 * 1024) {
      final mb = totalDataSize / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = totalDataSize / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() =>
      'SyncStatistics($totalVideos videos, ${getTotalDataSizeString()})';
}
