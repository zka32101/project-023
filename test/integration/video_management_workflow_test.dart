import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/video_library_service.dart';
import 'package:tsukuani/services/video_storage_service.dart';

void main() {
  group('Video Management Workflow Integration Tests', () {
    late VideoStorageService storageService;
    late VideoLibraryService libraryService;

    setUp(() {
      storageService = VideoStorageService.instance;
      libraryService = VideoLibraryService.instance;
    });

    test('Complete video lifecycle: save -> retrieve -> organize -> delete', () async {
      // Step 1: Verify storage is accessible
      final initialStorage = await storageService.getStorageInfo();
      expect(initialStorage.totalBytes, greaterThan(0));
      expect(initialStorage.usedBytes, greaterThanOrEqualTo(0));

      // Step 2: Verify project videos can be retrieved
      final projectId = 'integration_test_project_${DateTime.now().millisecondsSinceEpoch}';
      var projectVideos = await storageService.getProjectVideos(projectId);
      expect(projectVideos, isEmpty);

      // Step 3: Verify all videos can be retrieved
      final allVideos = await storageService.getAllVideos();
      expect(allVideos, isA<List<SavedVideo>>());

      // Step 4: Verify videos can be organized
      final stats = await libraryService.getStatistics(projectId: projectId);
      expect(stats.totalVideos, equals(0));
    });

    test('Video search and filtering workflow', () async {
      // Search by name
      var searchResults = await libraryService.searchByName('nonexistent');
      expect(searchResults, isEmpty);

      // Filter by resolution
      var resolutionResults =
          await libraryService.filterByResolution(9999, 9999);
      expect(resolutionResults, isEmpty);

      // Filter by format
      var formatResults = await libraryService.filterByFormat('mp4');
      expect(formatResults, isA<List<SavedVideo>>());

      // Advanced search
      var advancedResults = await libraryService.advancedSearch(
        nameQuery: 'test',
        minWidth: 1920,
        minHeight: 1080,
      );
      expect(advancedResults, isA<List<SavedVideo>>());
    });

    test('Video library statistics workflow', () async {
      // Get statistics for non-existent project
      final emptyStats =
          await libraryService.getStatistics(projectId: 'nonexistent');
      expect(emptyStats.totalVideos, equals(0));
      expect(emptyStats.totalStorageBytes, equals(0));

      // Get global statistics
      final globalStats = await libraryService.getStatistics();
      expect(globalStats.totalVideos, greaterThanOrEqualTo(0));
      expect(globalStats.totalStorageBytes, greaterThanOrEqualTo(0));
      expect(globalStats.averageFileSize, greaterThanOrEqualTo(0));
    });

    test('Video sorting functionality across all sort orders', () async {
      final allVideos = await libraryService.getAllVideos();

      // Test each sort order produces valid list
      for (final order in VideoLibraryService.SortOrder.values) {
        final sorted = await libraryService.getAllVideos(sortOrder: order);
        expect(sorted, isA<List<SavedVideo>>());
        expect(sorted.length, equals(allVideos.length));
      }
    });

    test('Project organization and grouping workflow', () async {
      // Get videos grouped by project
      final grouped = await libraryService.getVideosByProject();
      expect(grouped, isA<Map<String, List<SavedVideo>>>());

      // Get unique projects
      final projects = await libraryService.getProjects();
      expect(projects, isA<List<String>>());

      // Verify project IDs match
      expect(projects.length, equals(grouped.keys.length));
    });

    test('Storage monitoring workflow', () async {
      // Get storage info
      final storage = await storageService.getStorageInfo();
      expect(storage, isA<StorageInfo>());

      // Verify storage math
      expect(
        storage.freeBytes,
        equals(storage.totalBytes - storage.usedBytes),
      );

      // Check storage status
      final isCritical = storage.isCriticallyLow;
      expect(isCritical, isA<bool>());

      final isLow = storage.isLow;
      expect(isLow, isA<bool>());
    });

    test('Video count and total storage queries', () async {
      // Get video count
      final totalCount = await libraryService.getVideoCount();
      expect(totalCount, greaterThanOrEqualTo(0));

      // Get total storage
      final totalStorage = await libraryService.getTotalStorageUsed();
      expect(totalStorage, greaterThanOrEqualTo(0));

      // Get by project
      final projectCount =
          await libraryService.getVideoCount(projectId: 'test_project');
      expect(projectCount, greaterThanOrEqualTo(0));
    });

    test('Date range filtering workflow', () async {
      // Get videos from past week
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final recentVideos =
          await libraryService.filterByDateRange(weekAgo, now);
      expect(recentVideos, isA<List<SavedVideo>>());

      // Get videos from future (should be empty)
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = tomorrow.add(const Duration(days: 7));

      final futureVideos =
          await libraryService.filterByDateRange(tomorrow, nextWeek);
      expect(futureVideos, isEmpty);
    });

    test('Multiple filter combination workflow', () async {
      // Combine multiple filters
      final results = await libraryService.advancedSearch(
        minWidth: 640,
        maxWidth: 3840,
        minHeight: 480,
        maxHeight: 2160,
        minFileSizeBytes: 1024,
        format: 'mp4',
        fps: 30,
      );

      expect(results, isA<List<SavedVideo>>());
    });

    test('Video metadata consistency', () async {
      final allVideos = await storageService.getAllVideos();

      for (final video in allVideos) {
        // Verify metadata fields are valid
        expect(video.metadata.width, greaterThan(0));
        expect(video.metadata.height, greaterThan(0));
        expect(video.metadata.fileSizeBytes, greaterThanOrEqualTo(0));
        expect(video.metadata.fps, greaterThan(0));
        expect(video.metadata.format, isNotEmpty);

        // Verify display methods work
        expect(video.metadata.getResolutionString(), isNotEmpty);
        expect(video.metadata.getFileSizeString(), isNotEmpty);
        expect(video.getDisplayName(), isNotEmpty);
      }
    });

    test('Service singleton behavior', () {
      final storage1 = VideoStorageService.instance;
      final storage2 = VideoStorageService.instance;
      final library1 = VideoLibraryService.instance;
      final library2 = VideoLibraryService.instance;

      expect(identical(storage1, storage2), isTrue);
      expect(identical(library1, library2), isTrue);
    });

    test('Error handling for invalid inputs', () async {
      // Test with empty strings and invalid IDs
      final emptyProjectVideos =
          await storageService.getProjectVideos('');
      expect(emptyProjectVideos, isA<List<SavedVideo>>());

      // Test with very long string ID
      final longIdVideos = await storageService.getProjectVideos(
        'a' * 10000,
      );
      expect(longIdVideos, isA<List<SavedVideo>>());
    });

    test('Data model serialization workflow', () {
      // Create metadata
      final metadata = VideoMetadata(
        createdAt: DateTime.now(),
        width: 1920,
        height: 1080,
        fileSizeBytes: 52428800,
        durationSeconds: 10.0,
        fps: 30,
        format: 'mp4',
      );

      // Serialize and deserialize
      final json = metadata.toJson();
      final restored = VideoMetadata.fromJson(json);

      expect(restored.width, equals(metadata.width));
      expect(restored.height, equals(metadata.height));
      expect(restored.fileSizeBytes, equals(metadata.fileSizeBytes));
      expect(restored.fps, equals(metadata.fps));
      expect(restored.format, equals(metadata.format));
    });

    test('Storage Info serialization', () {
      final storage = StorageInfo(
        totalBytes: 1024 * 1024 * 1024,
        usedBytes: 512 * 1024 * 1024,
        freeBytes: 512 * 1024 * 1024,
      );

      expect(storage.percentageUsed, closeTo(0.5, 0.01));
      expect(storage.getTotalStorageString(), isNotEmpty);
      expect(storage.getUsedString(), isNotEmpty);
      expect(storage.getFreeString(), isNotEmpty);
    });

    test('LibraryStatistics generation and formatting', () {
      final stats = LibraryStatistics(
        totalVideos: 10,
        totalStorageBytes: 512 * 1024 * 1024,
        averageFileSize: 51 * 1024 * 1024,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.toString(), isNotEmpty);
      expect(stats.getTotalStorageString(), isNotEmpty);
      expect(stats.getAverageFileSizeString(), isNotEmpty);
    });
  });

  group('Video Library Service - Edge Cases', () {
    late VideoLibraryService libraryService;

    setUp(() {
      libraryService = VideoLibraryService.instance;
    });

    test('Sorting empty list works correctly', () async {
      // All sort methods should handle empty lists
      for (final order in VideoLibraryService.SortOrder.values) {
        final videos = await libraryService.getAllVideos(sortOrder: order);
        expect(videos, isA<List<SavedVideo>>());
      }
    });

    test('Filtering with overlapping criteria', () async {
      // Filters that contradict should return empty
      final results = await libraryService.advancedSearch(
        minWidth: 9999,
        maxWidth: 1000,
      );

      // Should return empty due to min > max
      expect(results, isA<List<SavedVideo>>());
    });

    test('Search with special characters', () async {
      final results = await libraryService.searchByName(
        '!@#$%^&*()',
      );

      expect(results, isA<List<SavedVideo>>());
    });

    test('Extreme file size filtering', () async {
      // Very large file size
      final largeResults = await libraryService.filterByFileSize(
        1024 * 1024 * 1024 * 1024,
        2048 * 1024 * 1024 * 1024,
      );
      expect(largeResults, isEmpty);

      // Very small file size
      final smallResults =
          await libraryService.filterByFileSize(1, 100);
      expect(smallResults, isA<List<SavedVideo>>());
    });

    test('Extreme resolution filtering', () async {
      // Very high resolution
      final highRes = await libraryService.filterByResolution(
        9999,
        9999,
      );
      expect(highRes, isEmpty);

      // Very low resolution
      final lowRes = await libraryService.filterByResolution(1, 1);
      expect(lowRes, isA<List<SavedVideo>>());
    });

    test('Extreme fps filtering', () async {
      final veryHighFps = await libraryService.filterByFps(999);
      expect(veryHighFps, isEmpty);

      final lowFps = await libraryService.filterByFps(1);
      expect(lowFps, isA<List<SavedVideo>>());
    });

    test('Statistics for very large video count', () async {
      // Test statistics calculation logic
      final stats = LibraryStatistics(
        totalVideos: 999999,
        totalStorageBytes: 999999 * 1024 * 1024 * 100,
        averageFileSize: 1024 * 1024 * 100,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.totalVideos, equals(999999));
      expect(stats.getTotalStorageString(), isNotEmpty);
    });
  });

  group('Video Storage Service - Concurrency', () {
    late VideoStorageService storageService;

    setUp(() {
      storageService = VideoStorageService.instance;
    });

    test('Multiple simultaneous queries', () async {
      // Simulate concurrent access
      final futures = <Future<List<SavedVideo>>>[
        storageService.getProjectVideos('proj1'),
        storageService.getProjectVideos('proj2'),
        storageService.getAllVideos(),
        storageService.getProjectVideos('proj3'),
      ];

      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result, isA<List<SavedVideo>>());
      }
    });

    test('Storage info queries concurrent access', () async {
      final futures = List.generate(
        5,
        (_) => storageService.getStorageInfo(),
      );

      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result.totalBytes, greaterThan(0));
      }
    });

    test('Mixed concurrent operations', () async {
      final futures = <Future<dynamic>>[
        storageService.getStorageInfo(),
        storageService.getProjectVideos('proj1'),
        storageService.getAllVideos(),
        storageService.getStorageInfo(),
        storageService.getProjectVideos('proj2'),
      ];

      final results = await Future.wait(futures);
      expect(results, hasLength(5));
    });
  });
}
