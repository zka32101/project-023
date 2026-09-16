import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_ranking.dart';

void main() {
  group('RankedVideo', () {
    test('getEngagementRate calculates correctly', () {
      final video = RankedVideo(
        videoId: 'vid1',
        title: 'Test Video',
        creatorId: 'creator1',
        viewCount: 1000,
        likeCount: 200,
        shareCount: 50,
        averageRating: 4.5,
        engagementScore: 450.0,
        rank: 1,
        period: RankingPeriod.daily,
        lastUpdated: DateTime.now(),
      );

      expect(video.getEngagementRate(), closeTo(25.0, 0.1));
    });

    test('getEngagementRate returns 0 for zero views', () {
      final video = RankedVideo(
        videoId: 'vid1',
        title: 'Test Video',
        creatorId: 'creator1',
        viewCount: 0,
        likeCount: 0,
        shareCount: 0,
        averageRating: 0.0,
        engagementScore: 0.0,
        rank: 1,
        period: RankingPeriod.daily,
        lastUpdated: DateTime.now(),
      );

      expect(video.getEngagementRate(), equals(0.0));
    });

    test('copyWith creates new instance with modified fields', () {
      final original = RankedVideo(
        videoId: 'vid1',
        title: 'Test Video',
        creatorId: 'creator1',
        viewCount: 100,
        likeCount: 10,
        shareCount: 5,
        averageRating: 4.0,
        engagementScore: 25.0,
        rank: 1,
        period: RankingPeriod.daily,
        lastUpdated: DateTime.now(),
      );

      final modified = original.copyWith(
        rank: 2,
        likeCount: 20,
      );

      expect(modified.rank, equals(2));
      expect(modified.likeCount, equals(20));
      expect(modified.videoId, equals(original.videoId));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = RankedVideo(
        videoId: 'vid1',
        title: 'Test Video',
        creatorId: 'creator1',
        viewCount: 500,
        likeCount: 50,
        shareCount: 25,
        averageRating: 4.5,
        engagementScore: 125.0,
        rank: 2,
        period: RankingPeriod.weekly,
        lastUpdated: now,
      );

      final json = original.toJson();
      final restored = RankedVideo.fromJson(json);

      expect(restored.videoId, equals(original.videoId));
      expect(restored.title, equals(original.title));
      expect(restored.rank, equals(original.rank));
      expect(restored.period, equals(original.period));
    });
  });

  group('UserRanking', () {
    test('getAverageViewsPerVideo calculates correctly', () {
      final ranking = UserRanking(
        userId: 'user1',
        displayName: 'Creator',
        totalVideos: 10,
        totalViews: 5000,
        totalLikes: 500,
        totalShares: 100,
        rank: 1,
        averageRating: 4.5,
        followerCount: 1000,
        lastUpdated: DateTime.now(),
      );

      expect(ranking.getAverageViewsPerVideo(), equals(500.0));
    });

    test('getAverageViewsPerVideo returns 0 for zero videos', () {
      final ranking = UserRanking(
        userId: 'user1',
        displayName: 'Creator',
        totalVideos: 0,
        totalViews: 0,
        totalLikes: 0,
        totalShares: 0,
        rank: 1,
        averageRating: 0.0,
        followerCount: 0,
        lastUpdated: DateTime.now(),
      );

      expect(ranking.getAverageViewsPerVideo(), equals(0.0));
    });

    test('getAverageEngagementPerVideo calculates correctly', () {
      final ranking = UserRanking(
        userId: 'user1',
        displayName: 'Creator',
        totalVideos: 10,
        totalViews: 5000,
        totalLikes: 500,
        totalShares: 100,
        rank: 1,
        averageRating: 4.5,
        followerCount: 1000,
        lastUpdated: DateTime.now(),
      );

      expect(ranking.getAverageEngagementPerVideo(), equals(60.0));
    });

    test('copyWith creates new instance with modified fields', () {
      final original = UserRanking(
        userId: 'user1',
        displayName: 'Creator',
        totalVideos: 5,
        totalViews: 1000,
        totalLikes: 100,
        totalShares: 20,
        rank: 1,
        averageRating: 4.0,
        followerCount: 500,
        lastUpdated: DateTime.now(),
      );

      final modified = original.copyWith(
        rank: 3,
        followerCount: 1000,
      );

      expect(modified.rank, equals(3));
      expect(modified.followerCount, equals(1000));
      expect(modified.userId, equals(original.userId));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = UserRanking(
        userId: 'user1',
        displayName: 'TopCreator',
        totalVideos: 50,
        totalViews: 100000,
        totalLikes: 10000,
        totalShares: 2000,
        rank: 1,
        averageRating: 4.8,
        followerCount: 5000,
        profileImageUrl: 'https://example.com/image.jpg',
        lastUpdated: now,
      );

      final json = original.toJson();
      final restored = UserRanking.fromJson(json);

      expect(restored.userId, equals(original.userId));
      expect(restored.displayName, equals(original.displayName));
      expect(restored.rank, equals(original.rank));
      expect(restored.profileImageUrl, equals(original.profileImageUrl));
    });
  });

  group('RankingPeriod Enum', () {
    test('all ranking periods are defined', () {
      expect(RankingPeriod.values, hasLength(3));
      expect(RankingPeriod.values, contains(RankingPeriod.daily));
      expect(RankingPeriod.values, contains(RankingPeriod.weekly));
      expect(RankingPeriod.values, contains(RankingPeriod.monthly));
    });
  });
}
