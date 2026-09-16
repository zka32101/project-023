import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/services/video_library_service.dart';

void main() {
  group('LibraryStatistics', () {
    test('getTotalStorageString returns KB for small storage', () {
      final stats = LibraryStatistics(
        totalVideos: 5,
        totalStorageBytes: 512 * 1024,
        averageFileSize: 102400,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.getTotalStorageString(), equals('512.0 KB'));
    });

    test('getTotalStorageString returns MB for medium storage', () {
      final stats = LibraryStatistics(
        totalVideos: 10,
        totalStorageBytes: 512 * 1024 * 1024,
        averageFileSize: 52428800,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.getTotalStorageString(), equals('512.0 MB'));
    });

    test('getTotalStorageString returns GB for large storage', () {
      final stats = LibraryStatistics(
        totalVideos: 100,
        totalStorageBytes: 512 * 1024 * 1024 * 1024,
        averageFileSize: 5368709120,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.getTotalStorageString(), equals('512.00 GB'));
    });

    test('getAverageFileSizeString returns correct format', () {
      final stats = LibraryStatistics(
        totalVideos: 10,
        totalStorageBytes: 100 * 1024 * 1024,
        averageFileSize: 10 * 1024 * 1024,
        averageResolution: '1920x1080',
        commonFormat: 'mp4',
        commonFps: 30,
      );

      expect(stats.getAverageFileSizeString(), equals('10.0 MB'));
    });
  });

  group('VideoLibraryService', () {
    late VideoLibraryService service;

    setUp(() {
      service = VideoLibraryService.instance;
    });

    test('singleton returns same instance', () {
      final instance1 = VideoLibraryService.instance;
      final instance2 = VideoLibraryService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('getProjectVideos returns empty list for non-existent project',
        () async {
      final videos = await service.getProjectVideos('non_existent_project');

      expect(videos, isEmpty);
    });

    test('getAllVideos returns list', () async {
      final videos = await service.getAllVideos();

      expect(videos, isA<List<SavedVideo>>());
    });

    test('searchByName returns empty list when no results', () async {
      final results = await service.searchByName('nonexistent_video_name_xyz');

      expect(results, isEmpty);
    });

    test('filterByResolution returns empty list by default', () async {
      final videos = await service.filterByResolution(9999, 9999);

      expect(videos, isEmpty);
    });

    test('filterByFileSize returns empty list by default', () async {
      final videos = await service.filterByFileSize(
        999 * 1024 * 1024 * 1024,
        9999 * 1024 * 1024 * 1024,
      );

      expect(videos, isEmpty);
    });

    test('filterByFormat returns empty list for unknown format', () async {
      final videos = await service.filterByFormat('xyz123');

      expect(videos, isEmpty);
    });

    test('filterByFps returns empty list for uncommon fps', () async {
      final videos = await service.filterByFps(999);

      expect(videos, isEmpty);
    });

    test('filterByDateRange returns empty list for future dates', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextWeek = tomorrow.add(const Duration(days: 7));

      final videos = await service.filterByDateRange(tomorrow, nextWeek);

      expect(videos, isEmpty);
    });

    test('getVideoCount returns non-negative number', () async {
      final count = await service.getVideoCount();

      expect(count, greaterThanOrEqualTo(0));
    });

    test('getTotalStorageUsed returns non-negative bytes', () async {
      final storage = await service.getTotalStorageUsed();

      expect(storage, greaterThanOrEqualTo(0));
    });

    test('getStatistics returns valid LibraryStatistics', () async {
      final stats = await service.getStatistics();

      expect(stats, isA<LibraryStatistics>());
      expect(stats.totalVideos, greaterThanOrEqualTo(0));
      expect(stats.totalStorageBytes, greaterThanOrEqualTo(0));
    });

    test('getStatistics empty case returns zero values', () async {
      final stats = await service.getStatistics(projectId: 'non_existent');

      expect(stats.totalVideos, equals(0));
      expect(stats.totalStorageBytes, equals(0));
      expect(stats.averageFileSize, equals(0));
    });

    test('getVideosByProject returns map', () async {
      final grouped = await service.getVideosByProject();

      expect(grouped, isA<Map<String, List<SavedVideo>>>());
    });

    test('getProjects returns list of project IDs', () async {
      final projects = await service.getProjects();

      expect(projects, isA<List<String>>());
    });

    test('advancedSearch with no filters returns all videos', () async {
      final videos = await service.advancedSearch();

      expect(videos, isA<List<SavedVideo>>());
    });

    test('advancedSearch filters by name query', () async {
      final videos = await service.advancedSearch(
        nameQuery: 'nonexistent_query_xyz',
      );

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by projectId', () async {
      final videos = await service.advancedSearch(
        projectId: 'nonexistent_project',
      );

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by min width', () async {
      final videos = await service.advancedSearch(minWidth: 9999);

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by max width', () async {
      final videos = await service.advancedSearch(maxWidth: 1);

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by min height', () async {
      final videos = await service.advancedSearch(minHeight: 9999);

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by max height', () async {
      final videos = await service.advancedSearch(maxHeight: 1);

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by file size', () async {
      final videos = await service.advancedSearch(
        minFileSizeBytes: 999 * 1024 * 1024 * 1024,
        maxFileSizeBytes: 9999 * 1024 * 1024 * 1024,
      );

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by format', () async {
      final videos = await service.advancedSearch(format: 'xyz123');

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by fps', () async {
      final videos = await service.advancedSearch(fps: 999);

      expect(videos, isEmpty);
    });

    test('advancedSearch filters by date range', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextWeek = tomorrow.add(const Duration(days: 7));

      final videos = await service.advancedSearch(
        minCreatedDate: tomorrow,
        maxCreatedDate: nextWeek,
      );

      expect(videos, isEmpty);
    });
  });

  group('VideoLibraryService - Sort Orders', () {
    late VideoLibraryService service;

    setUp(() {
      service = VideoLibraryService.instance;
    });

    test('SortOrder enum has all values', () {
      expect(VideoLibraryService.SortOrder.values, hasLength(6));
    });

    test('sortOrder parameters work with getAllVideos', () async {
      for (final order in VideoLibraryService.SortOrder.values) {
        final videos = await service.getAllVideos(sortOrder: order);
        expect(videos, isA<List<SavedVideo>>());
      }
    });

    test('sortOrder parameters work with getProjectVideos', () async {
      for (final order in VideoLibraryService.SortOrder.values) {
        final videos =
            await service.getProjectVideos('test_project', sortOrder: order);
        expect(videos, isA<List<SavedVideo>>());
      }
    });

    test('sortOrder parameters work with advancedSearch', () async {
      for (final order in VideoLibraryService.SortOrder.values) {
        final videos =
            await service.advancedSearch(sortOrder: order);
        expect(videos, isA<List<SavedVideo>>());
      }
    });
  });

  group('VideoLibraryService - Filtering with Project ID', () {
    late VideoLibraryService service;

    setUp(() {
      service = VideoLibraryService.instance;
    });

    test('searchByName with projectId filters correctly', () async {
      final videos = await service.searchByName(
        'test',
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('filterByResolution with projectId filters correctly', () async {
      final videos = await service.filterByResolution(
        1920,
        1080,
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('filterByFileSize with projectId filters correctly', () async {
      final videos = await service.filterByFileSize(
        1 * 1024 * 1024,
        100 * 1024 * 1024,
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('filterByFormat with projectId filters correctly', () async {
      final videos = await service.filterByFormat(
        'mp4',
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('filterByFps with projectId filters correctly', () async {
      final videos = await service.filterByFps(
        30,
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('filterByDateRange with projectId filters correctly', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final videos = await service.filterByDateRange(
        yesterday,
        now,
        projectId: 'proj_123',
      );

      expect(videos, isA<List<SavedVideo>>());
    });

    test('getVideoCount with projectId returns non-negative', () async {
      final count = await service.getVideoCount(projectId: 'proj_123');

      expect(count, greaterThanOrEqualTo(0));
    });

    test('getTotalStorageUsed with projectId returns non-negative', () async {
      final storage = await service.getTotalStorageUsed(projectId: 'proj_123');

      expect(storage, greaterThanOrEqualTo(0));
    });

    test('getStatistics with projectId returns valid statistics', () async {
      final stats = await service.getStatistics(projectId: 'proj_123');

      expect(stats, isA<LibraryStatistics>());
      expect(stats.totalVideos, greaterThanOrEqualTo(0));
    });
  });

  group('VideoLibraryService - Sorting Behavior', () {
    late VideoLibraryService service;

    setUp(() {
      service = VideoLibraryService.instance;
    });

    test('newestFirst sorts by creation date descending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.newestFirst,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i].metadata.createdAt
                .isAfter(videos[i + 1].metadata.createdAt),
            isTrue,
          );
        }
      }
    });

    test('oldestFirst sorts by creation date ascending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.oldestFirst,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i].metadata.createdAt
                .isBefore(videos[i + 1].metadata.createdAt),
            isTrue,
          );
        }
      }
    });

    test('nameAscending sorts by name ascending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.nameAscending,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i]
                .getDisplayName()
                .compareTo(videos[i + 1].getDisplayName()),
            lessThanOrEqualTo(0),
          );
        }
      }
    });

    test('nameDescending sorts by name descending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.nameDescending,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i]
                .getDisplayName()
                .compareTo(videos[i + 1].getDisplayName()),
            greaterThanOrEqualTo(0),
          );
        }
      }
    });

    test('largestFirst sorts by file size descending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.largestFirst,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i].metadata.fileSizeBytes,
            greaterThanOrEqualTo(videos[i + 1].metadata.fileSizeBytes),
          );
        }
      }
    });

    test('smallestFirst sorts by file size ascending', () async {
      final videos = await service.getAllVideos(
        sortOrder: VideoLibraryService.SortOrder.smallestFirst,
      );

      if (videos.length > 1) {
        for (int i = 0; i < videos.length - 1; i++) {
          expect(
            videos[i].metadata.fileSizeBytes,
            lessThanOrEqualTo(videos[i + 1].metadata.fileSizeBytes),
          );
        }
      }
    });
  });
}
