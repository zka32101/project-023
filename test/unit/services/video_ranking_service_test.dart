import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_ranking.dart';
import 'package:tsukuani/services/video_ranking_service.dart';

void main() {
  group('VideoRankingService', () {
    late VideoRankingService service;

    setUp(() {
      service = VideoRankingService.instance;
      service.clearData();
    });

    test('singleton returns same instance', () {
      final instance1 = VideoRankingService.instance;
      final instance2 = VideoRankingService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('incrementViewCount increases view count', () async {
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['viewCount'], equals(2));
    });

    test('addLike increases like count', () async {
      await service.addLike('video1');
      await service.addLike('video1');

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['likeCount'], equals(2));
    });

    test('removeLike decreases like count', () async {
      await service.addLike('video1');
      await service.addLike('video1');
      await service.removeLike('video1');

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['likeCount'], equals(1));
    });

    test('addShare increases share count', () async {
      await service.addShare('video1');
      await service.addShare('video1');

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['shareCount'], equals(2));
    });

    test('addRating adds rating to video', () async {
      await service.addRating('video1', 5);
      await service.addRating('video1', 4);

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['averageRating'], closeTo(4.5, 0.01));
    });

    test('addRating ignores invalid ratings', () async {
      await service.addRating('video1', 6);
      await service.addRating('video1', 0);
      await service.addRating('video1', 5);

      final stats = await service.getVideoEngagementStats('video1');
      expect(stats['averageRating'], equals(5.0));
    });

    test('getDailyRanking returns sorted videos', () async {
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video2');
      await service.incrementViewCount('video2');
      await service.addLike('video2');

      final ranking = await service.getDailyRanking();

      expect(ranking, isNotEmpty);
      expect(ranking.first.rank, equals(1));
    });

    test('getWeeklyRanking returns videos', () async {
      await service.incrementViewCount('video1');
      await service.addLike('video1');

      final ranking = await service.getWeeklyRanking();

      expect(ranking.isNotEmpty, isTrue);
    });

    test('getMonthlyRanking returns videos', () async {
      await service.incrementViewCount('video1');

      final ranking = await service.getMonthlyRanking();

      expect(ranking.isNotEmpty, isTrue);
    });

    test('getDailyRanking respects limit', () async {
      for (int i = 0; i < 15; i++) {
        await service.incrementViewCount('video$i');
      }

      final ranking = await service.getDailyRanking(limit: 5);

      expect(ranking, hasLength(5));
    });

    test('getVideoEngagementStats returns zero for non-existent video', () async {
      final stats = await service.getVideoEngagementStats('nonexistent');

      expect(stats['viewCount'], equals(0));
      expect(stats['likeCount'], equals(0));
      expect(stats['engagementRate'], equals(0.0));
    });

    test('getVideoEngagementStats calculates engagement rate', () async {
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.incrementViewCount('video1');
      await service.addLike('video1');
      await service.addShare('video1');

      final stats = await service.getVideoEngagementStats('video1');

      expect(stats['engagementRate'], closeTo(20.0, 0.1));
    });

    test('updateUserStats sets video count', () async {
      await service.updateUserStats('user1', 'Creator', 5);

      final ranking = await service.getCreatorRanking();

      expect(ranking, isNotEmpty);
    });

    test('updateFollowerCount updates follower count', () async {
      await service.updateUserStats('user1', 'Creator', 5);
      await service.updateFollowerCount('user1', 1000);

      final ranking = await service.getCreatorRanking();

      expect(ranking.isNotEmpty, isTrue);
    });

    test('getCreatorRanking returns creators sorted by engagement', () async {
      await service.updateUserStats('user1', 'Creator1', 5);
      await service.updateUserStats('user2', 'Creator2', 3);

      // Add engagement data
      for (int i = 0; i < 5; i++) {
        await service.incrementViewCount('vid_user1_$i');
        await service.addLike('vid_user1_$i');
      }

      final ranking = await service.getCreatorRanking();

      expect(ranking, isNotEmpty);
      expect(ranking.first.rank, equals(1));
    });

    test('multiple concurrent view increments succeed', () async {
      final futures = List.generate(
        10,
        (_) => service.incrementViewCount('video1'),
      );

      await Future.wait(futures);
      final stats = await service.getVideoEngagementStats('video1');

      expect(stats['viewCount'], equals(10));
    });

    test('concurrent likes and views work correctly', () async {
      final futures = <Future>[];

      for (int i = 0; i < 5; i++) {
        futures.add(service.incrementViewCount('video1'));
        futures.add(service.addLike('video1'));
      }

      await Future.wait(futures);
      final stats = await service.getVideoEngagementStats('video1');

      expect(stats['viewCount'], equals(5));
      expect(stats['likeCount'], equals(5));
    });
  });
}
