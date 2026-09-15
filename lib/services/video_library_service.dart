/// Video library service for organizing and managing saved videos

import 'dart:async';

import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/video_storage_service.dart';

/// Service for managing video library operations
class VideoLibraryService {
  static VideoLibraryService? _instance;

  final VideoStorageService _storageService = VideoStorageService.instance;

  /// Singleton instance
  static VideoLibraryService get instance {
    _instance ??= VideoLibraryService._();
    return _instance;
  }

  VideoLibraryService._();

  /// Sort order for video listings
  enum SortOrder {
    newestFirst,
    oldestFirst,
    largestFirst,
    smallestFirst,
    nameAscending,
    nameDescending,
  }

  /// Get videos for a project with filtering and sorting
  Future<List<SavedVideo>> getProjectVideos(
    String projectId, {
    SortOrder sortOrder = SortOrder.newestFirst,
    bool? includeDeleted,
  }) async {
    final videos = await _storageService.getProjectVideos(projectId);
    return _sortVideos(videos, sortOrder);
  }

  /// Get all videos with filtering and sorting
  Future<List<SavedVideo>> getAllVideos({
    SortOrder sortOrder = SortOrder.newestFirst,
  }) async {
    final videos = await _storageService.getAllVideos();
    return _sortVideos(videos, sortOrder);
  }

  /// Search videos by display name
  Future<List<SavedVideo>> searchByName(
    String query, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    final lowerQuery = query.toLowerCase();
    return videos.where((video) {
      final name = video.getDisplayName().toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  /// Filter videos by resolution
  Future<List<SavedVideo>> filterByResolution(
    int width,
    int height, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    return videos.where((video) {
      return video.metadata.width == width && video.metadata.height == height;
    }).toList();
  }

  /// Filter videos by file size range (in bytes)
  Future<List<SavedVideo>> filterByFileSize(
    int minBytes,
    int maxBytes, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    return videos.where((video) {
      final size = video.metadata.fileSizeBytes;
      return size >= minBytes && size <= maxBytes;
    }).toList();
  }

  /// Filter videos by format (mp4, webm, mov)
  Future<List<SavedVideo>> filterByFormat(
    String format, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    final lowerFormat = format.toLowerCase();
    return videos
        .where((video) => video.metadata.format.toLowerCase() == lowerFormat)
        .toList();
  }

  /// Filter videos by fps
  Future<List<SavedVideo>> filterByFps(
    int fps, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    return videos.where((video) => video.metadata.fps == fps).toList();
  }

  /// Filter videos by creation date range
  Future<List<SavedVideo>> filterByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? projectId,
  }) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    return videos.where((video) {
      final created = video.metadata.createdAt;
      return created.isAfter(startDate) && created.isBefore(endDate);
    }).toList();
  }

  /// Advanced search with multiple filters
  Future<List<SavedVideo>> advancedSearch({
    String? nameQuery,
    String? projectId,
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
    int? minFileSizeBytes,
    int? maxFileSizeBytes,
    String? format,
    int? fps,
    DateTime? minCreatedDate,
    DateTime? maxCreatedDate,
    SortOrder sortOrder = SortOrder.newestFirst,
  }) async {
    var videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    // Apply filters
    if (nameQuery != null && nameQuery.isNotEmpty) {
      final lowerQuery = nameQuery.toLowerCase();
      videos = videos
          .where((v) => v.getDisplayName().toLowerCase().contains(lowerQuery))
          .toList();
    }

    if (minWidth != null) {
      videos = videos.where((v) => v.metadata.width >= minWidth).toList();
    }
    if (maxWidth != null) {
      videos = videos.where((v) => v.metadata.width <= maxWidth).toList();
    }

    if (minHeight != null) {
      videos = videos.where((v) => v.metadata.height >= minHeight).toList();
    }
    if (maxHeight != null) {
      videos = videos.where((v) => v.metadata.height <= maxHeight).toList();
    }

    if (minFileSizeBytes != null) {
      videos = videos
          .where((v) => v.metadata.fileSizeBytes >= minFileSizeBytes)
          .toList();
    }
    if (maxFileSizeBytes != null) {
      videos = videos
          .where((v) => v.metadata.fileSizeBytes <= maxFileSizeBytes)
          .toList();
    }

    if (format != null) {
      final lowerFormat = format.toLowerCase();
      videos = videos
          .where((v) => v.metadata.format.toLowerCase() == lowerFormat)
          .toList();
    }

    if (fps != null) {
      videos = videos.where((v) => v.metadata.fps == fps).toList();
    }

    if (minCreatedDate != null) {
      videos = videos
          .where((v) => v.metadata.createdAt.isAfter(minCreatedDate))
          .toList();
    }
    if (maxCreatedDate != null) {
      videos = videos
          .where((v) => v.metadata.createdAt.isBefore(maxCreatedDate))
          .toList();
    }

    return _sortVideos(videos, sortOrder);
  }

  /// Get total video count
  Future<int> getVideoCount({String? projectId}) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();
    return videos.length;
  }

  /// Get total storage used by videos (in bytes)
  Future<int> getTotalStorageUsed({String? projectId}) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    return videos.fold<int>(
      0,
      (total, video) => total + video.metadata.fileSizeBytes,
    );
  }

  /// Get statistics for videos in a project or globally
  Future<LibraryStatistics> getStatistics({String? projectId}) async {
    final videos = projectId != null
        ? await _storageService.getProjectVideos(projectId)
        : await _storageService.getAllVideos();

    if (videos.isEmpty) {
      return LibraryStatistics(
        totalVideos: 0,
        totalStorageBytes: 0,
        averageFileSize: 0,
        averageResolution: '0x0',
        commonFormat: 'N/A',
        commonFps: 0,
      );
    }

    int totalStorage = 0;
    final resolutions = <String, int>{};
    final formats = <String, int>{};
    final fpsList = <int, int>{};

    for (final video in videos) {
      totalStorage += video.metadata.fileSizeBytes;

      final res = video.metadata.getResolutionString();
      resolutions[res] = (resolutions[res] ?? 0) + 1;

      final fmt = video.metadata.format;
      formats[fmt] = (formats[fmt] ?? 0) + 1;

      final fps = video.metadata.fps;
      fpsList[fps] = (fpsList[fps] ?? 0) + 1;
    }

    // Find most common values
    final commonRes = resolutions.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key ??
        '0x0';
    final commonFmt =
        formats.entries.reduce((a, b) => a.value > b.value ? a : b).key ??
            'unknown';
    final commonFpsVal =
        fpsList.entries.reduce((a, b) => a.value > b.value ? a : b).key ?? 0;

    return LibraryStatistics(
      totalVideos: videos.length,
      totalStorageBytes: totalStorage,
      averageFileSize: totalStorage ~/ videos.length,
      averageResolution: commonRes,
      commonFormat: commonFmt,
      commonFps: commonFpsVal,
    );
  }

  /// Get videos grouped by project
  Future<Map<String, List<SavedVideo>>> getVideosByProject() async {
    final allVideos = await _storageService.getAllVideos();
    final grouped = <String, List<SavedVideo>>{};

    for (final video in allVideos) {
      grouped.putIfAbsent(video.projectId, () => []).add(video);
    }

    return grouped;
  }

  /// Get unique projects
  Future<List<String>> getProjects() async {
    final grouped = await getVideosByProject();
    return grouped.keys.toList();
  }

  /// Sort videos by the specified order
  List<SavedVideo> _sortVideos(
    List<SavedVideo> videos,
    SortOrder sortOrder,
  ) {
    final sorted = List<SavedVideo>.from(videos);

    switch (sortOrder) {
      case SortOrder.newestFirst:
        sorted.sort(
          (a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt),
        );
      case SortOrder.oldestFirst:
        sorted.sort(
          (a, b) => a.metadata.createdAt.compareTo(b.metadata.createdAt),
        );
      case SortOrder.largestFirst:
        sorted.sort(
          (a, b) =>
              b.metadata.fileSizeBytes.compareTo(a.metadata.fileSizeBytes),
        );
      case SortOrder.smallestFirst:
        sorted.sort(
          (a, b) =>
              a.metadata.fileSizeBytes.compareTo(b.metadata.fileSizeBytes),
        );
      case SortOrder.nameAscending:
        sorted.sort((a, b) =>
            a.getDisplayName().compareTo(b.getDisplayName()));
      case SortOrder.nameDescending:
        sorted.sort((a, b) =>
            b.getDisplayName().compareTo(a.getDisplayName()));
    }

    return sorted;
  }
}

/// Statistics about video library
class LibraryStatistics {
  /// Total number of videos
  final int totalVideos;

  /// Total storage used in bytes
  final int totalStorageBytes;

  /// Average file size in bytes
  final int averageFileSize;

  /// Most common video resolution
  final String averageResolution;

  /// Most common video format
  final String commonFormat;

  /// Most common frame rate
  final int commonFps;

  LibraryStatistics({
    required this.totalVideos,
    required this.totalStorageBytes,
    required this.averageFileSize,
    required this.averageResolution,
    required this.commonFormat,
    required this.commonFps,
  });

  /// Get total storage as human-readable string
  String getTotalStorageString() {
    if (totalStorageBytes < 1024 * 1024) {
      final kb = totalStorageBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (totalStorageBytes < 1024 * 1024 * 1024) {
      final mb = totalStorageBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = totalStorageBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// Get average file size as human-readable string
  String getAverageFileSizeString() {
    if (averageFileSize < 1024 * 1024) {
      final kb = averageFileSize / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (averageFileSize < 1024 * 1024 * 1024) {
      final mb = averageFileSize / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = averageFileSize / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() =>
      'LibraryStatistics($totalVideos videos, ${getTotalStorageString()})';
}
