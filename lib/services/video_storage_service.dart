/// Video storage service for managing saved videos

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tsukuani/models/video_storage_models.dart';

/// Service for managing video storage operations
class VideoStorageService {
  static VideoStorageService? _instance;

  /// Videos directory name
  static const String _videosDir = 'videos';

  /// Metadata file suffix
  static const String _metadataFileSuffix = '.metadata.json';

  /// Singleton instance
  static VideoStorageService get instance {
    _instance ??= VideoStorageService._();
    return _instance;
  }

  VideoStorageService._();

  /// Get the videos directory path
  Future<String> _getVideosDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_videosDir';
  }

  /// Ensure videos directory exists
  Future<Directory> _ensureVideosDirExists() async {
    final dirPath = await _getVideosDirPath();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save a video file from temporary location
  Future<SavedVideo> saveVideo(
    String tempVideoPath,
    String projectId, {
    String? displayName,
    int? width,
    int? height,
    int? fps,
    double? durationSeconds,
  }) async {
    // Validate input file
    final sourceFile = File(tempVideoPath);
    if (!await sourceFile.exists()) {
      throw Exception('Source video file not found: $tempVideoPath');
    }

    // Ensure videos directory exists
    await _ensureVideosDirExists();

    // Extract file extension from source
    final sourceExt = sourceFile.path.split('.').last;

    // Generate unique video ID
    final videoId = _generateId();

    // Determine video directory (organized by project)
    final dirPath = await _getVideosDirPath();
    final projectDir = Directory('$dirPath/$projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    // Copy video file to storage location
    final fileName = '$videoId.$sourceExt';
    final destinationPath = '${projectDir.path}/$fileName';
    final destinationFile = await sourceFile.copy(destinationPath);

    // Get file size
    final fileSizeBytes = await destinationFile.length();

    // Get file modified time (use current time)
    final createdAt = DateTime.now();

    // Create metadata
    final metadata = VideoMetadata(
      createdAt: createdAt,
      width: width ?? 1920,
      height: height ?? 1080,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds ?? 0.0,
      fps: fps ?? 30,
      format: sourceExt.toLowerCase(),
    );

    // Save metadata
    await _saveMetadata(videoId, projectId, metadata);

    // Create and return SavedVideo object
    return SavedVideo(
      id: videoId,
      projectId: projectId,
      filePath: destinationPath,
      metadata: metadata,
      displayName: displayName,
    );
  }

  /// Save metadata for a video
  Future<void> _saveMetadata(
    String videoId,
    String projectId,
    VideoMetadata metadata,
  ) async {
    final dirPath = await _getVideosDirPath();
    final metadataPath =
        '$dirPath/$projectId/$videoId$_metadataFileSuffix';
    final metadataFile = File(metadataPath);

    final jsonData = jsonEncode(metadata.toJson());
    await metadataFile.writeAsString(jsonData);
  }

  /// Load metadata for a video
  Future<VideoMetadata?> _loadMetadata(
    String videoId,
    String projectId,
  ) async {
    try {
      final dirPath = await _getVideosDirPath();
      final metadataPath =
          '$dirPath/$projectId/$videoId$_metadataFileSuffix';
      final metadataFile = File(metadataPath);

      if (!await metadataFile.exists()) {
        return null;
      }

      final jsonString = await metadataFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return VideoMetadata.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Get metadata for a video
  Future<VideoMetadata?> getVideoMetadata(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      // Try to find and load metadata file
      final metadataPath = '${videoPath.replaceAll(
        RegExp(r'\.[^.]+$'),
        '',
      )}$_metadataFileSuffix';
      final metadataFile = File(metadataPath);

      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return VideoMetadata.fromJson(jsonData);
      }

      // Fallback: create basic metadata from file info
      final stat = await file.stat();
      return VideoMetadata(
        createdAt: stat.modified,
        width: 1920,
        height: 1080,
        fileSizeBytes: stat.size,
        durationSeconds: 0.0,
        fps: 30,
        format: videoPath.split('.').last.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all videos for a project
  Future<List<SavedVideo>> getProjectVideos(String projectId) async {
    try {
      final dirPath = await _getVideosDirPath();
      final projectDir = Directory('$dirPath/$projectId');

      if (!await projectDir.exists()) {
        return [];
      }

      final videos = <SavedVideo>[];
      final files = projectDir.listSync();

      for (final entity in files) {
        if (entity is File && !entity.path.endsWith(_metadataFileSuffix)) {
          // Extract video ID from filename
          final filename = entity.path.split('/').last;
          final videoId = filename.split('.').first;

          // Load metadata
          final metadata = await _loadMetadata(videoId, projectId);
          if (metadata != null) {
            videos.add(SavedVideo(
              id: videoId,
              projectId: projectId,
              filePath: entity.path,
              metadata: metadata,
            ));
          }
        }
      }

      // Sort by creation date (newest first)
      videos.sort(
        (a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt),
      );

      return videos;
    } catch (e) {
      return [];
    }
  }

  /// Get all videos across all projects
  Future<List<SavedVideo>> getAllVideos() async {
    try {
      final dirPath = await _getVideosDirPath();
      final videosDir = Directory(dirPath);

      if (!await videosDir.exists()) {
        return [];
      }

      final allVideos = <SavedVideo>[];
      final projectDirs = videosDir.listSync();

      for (final entity in projectDirs) {
        if (entity is Directory) {
          final projectId = entity.path.split('/').last;
          final projectVideos = await getProjectVideos(projectId);
          allVideos.addAll(projectVideos);
        }
      }

      // Sort by creation date (newest first)
      allVideos.sort(
        (a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt),
      );

      return allVideos;
    } catch (e) {
      return [];
    }
  }

  /// Get storage information
  Future<StorageInfo> getStorageInfo() async {
    try {
      final dirPath = await _getVideosDirPath();
      final videosDir = Directory(dirPath);

      int totalUsedBytes = 0;

      if (await videosDir.exists()) {
        final files = videosDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => !f.path.endsWith(_metadataFileSuffix));

        for (final file in files) {
          totalUsedBytes += await file.length();
        }
      }

      // Get device storage info
      // Note: This is a simplified implementation
      // For real device info, you would need to use platform channels
      const totalDeviceBytes = 64 * 1024 * 1024 * 1024; // Assume 64GB
      final freeBytes = totalDeviceBytes - totalUsedBytes;

      return StorageInfo(
        totalBytes: totalDeviceBytes,
        usedBytes: totalUsedBytes,
        freeBytes: freeBytes,
      );
    } catch (e) {
      // Fallback storage info
      return StorageInfo(
        totalBytes: 64 * 1024 * 1024 * 1024,
        usedBytes: 0,
        freeBytes: 64 * 1024 * 1024 * 1024,
      );
    }
  }

  /// Delete a video
  Future<bool> deleteVideo(String videoId, String projectId) async {
    try {
      final dirPath = await _getVideosDirPath();
      final projectDir = '$dirPath/$projectId';

      // Find and delete video file
      final dir = Directory(projectDir);
      final files = dir.listSync();

      bool deleted = false;
      for (final entity in files) {
        if (entity is File) {
          final filename = entity.path.split('/').last;
          final fileVideoId = filename.split('.').first;

          if (fileVideoId == videoId) {
            await entity.delete();
            deleted = true;
            break;
          }
        }
      }

      // Delete metadata file if it exists
      final metadataPath =
          '$projectDir/$videoId$_metadataFileSuffix';
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      return deleted;
    } catch (e) {
      return false;
    }
  }

  /// Delete all videos for a project
  Future<bool> deleteProjectVideos(String projectId) async {
    try {
      final dirPath = await _getVideosDirPath();
      final projectDir = Directory('$dirPath/$projectId');

      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Export video (copy to external location)
  Future<bool> exportVideo(String videoId, String projectId, String destination) async {
    try {
      final dirPath = await _getVideosDirPath();
      final projectDir = '$dirPath/$projectId';

      // Find video file
      final dir = Directory(projectDir);
      final files = dir.listSync();

      for (final entity in files) {
        if (entity is File) {
          final filename = entity.path.split('/').last;
          final fileVideoId = filename.split('.').first;

          if (fileVideoId == videoId) {
            final sourceFile = File(entity.path);
            final destFile = File(destination);
            await sourceFile.copy(destFile.path);
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Search for videos by creation date range
  Future<List<SavedVideo>> searchVideosByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allVideos = await getAllVideos();
      return allVideos.where((video) {
        final created = video.metadata.createdAt;
        return created.isAfter(startDate) && created.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
