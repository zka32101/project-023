/// Service for managing video rankings and engagement metrics

import 'package:tsukuani/models/video_ranking.dart';

/// Service for tracking and retrieving video rankings
class VideoRankingService {
  static VideoRankingService? _instance;

  /// Storage for video engagement data
  final Map<String, _VideoEngagement> _engagementData = {};

  /// Storage for user ranking data
  final Map<String, _UserStats> _userStats = {};

  /// Singleton instance
  static VideoRankingService get instance {
    _instance ??= VideoRankingService._();
    return _instance;
  }

  VideoRankingService._();

  /// Increment view count for a video
  Future<void> incrementViewCount(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final engagement = _engagementData.putIfAbsent(
      videoId,
      () => _VideoEngagement(videoId: videoId),
    );
    engagement.viewCount++;
  }

  /// Add like to a video
  Future<void> addLike(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final engagement = _engagementData.putIfAbsent(
      videoId,
      () => _VideoEngagement(videoId: videoId),
    );
    engagement.likeCount++;
  }

  /// Remove like from a video
  Future<void> removeLike(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final engagement = _engagementData[videoId];
    if (engagement != null && engagement.likeCount > 0) {
      engagement.likeCount--;
    }
  }

  /// Add share to a video
  Future<void> addShare(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final engagement = _engagementData.putIfAbsent(
      videoId,
      () => _VideoEngagement(videoId: videoId),
    );
    engagement.shareCount++;
  }

  /// Add rating to a video
  Future<void> addRating(String videoId, int rating) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (rating < 1 || rating > 5) return;

    final engagement = _engagementData.putIfAbsent(
      videoId,
      () => _VideoEngagement(videoId: videoId),
    );
    engagement.ratings.add(rating);
  }

  /// Get daily ranking
  Future<List<RankedVideo>> getDailyRanking({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getRanking(RankingPeriod.daily, limit);
  }

  /// Get weekly ranking
  Future<List<RankedVideo>> getWeeklyRanking({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getRanking(RankingPeriod.weekly, limit);
  }

  /// Get monthly ranking
  Future<List<RankedVideo>> getMonthlyRanking({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getRanking(RankingPeriod.monthly, limit);
  }

  /// Get creator ranking
  Future<List<UserRanking>> getCreatorRanking({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final rankings = _userStats.values.map((stats) {
      final avgRating =
          stats.ratings.isNotEmpty ? stats.ratings.reduce((a, b) => a + b) / stats.ratings.length : 0.0;
      return UserRanking(
        userId: stats.userId,
        displayName: stats.displayName,
        totalVideos: stats.totalVideos,
        totalViews: stats.totalViews,
        totalLikes: stats.totalLikes,
        totalShares: stats.totalShares,
        rank: 0,
        averageRating: avgRating,
        followerCount: stats.followerCount,
        lastUpdated: DateTime.now(),
      );
    }).toList();

    // Sort by engagement score
    rankings.sort((a, b) {
      final scoreA = (a.totalViews * 0.3) + (a.totalLikes * 1.0) + (a.totalShares * 2.0);
      final scoreB = (b.totalViews * 0.3) + (b.totalLikes * 1.0) + (b.totalShares * 2.0);
      return scoreB.compareTo(scoreA);
    });

    // Assign ranks and return limited results
    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = rankings[i].copyWith(rank: i + 1);
    }

    return rankings.take(limit).toList();
  }

  /// Get engagement statistics for a video
  Future<Map<String, dynamic>> getVideoEngagementStats(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final engagement = _engagementData[videoId];
    if (engagement == null) {
      return {
        'videoId': videoId,
        'viewCount': 0,
        'likeCount': 0,
        'shareCount': 0,
        'averageRating': 0.0,
        'engagementRate': 0.0,
      };
    }

    final avgRating =
        engagement.ratings.isNotEmpty ? engagement.ratings.reduce((a, b) => a + b) / engagement.ratings.length : 0.0;
    final engagementRate = engagement.viewCount > 0
        ? ((engagement.likeCount + engagement.shareCount) / engagement.viewCount) * 100
        : 0.0;

    return {
      'videoId': videoId,
      'viewCount': engagement.viewCount,
      'likeCount': engagement.likeCount,
      'shareCount': engagement.shareCount,
      'averageRating': avgRating,
      'engagementRate': engagementRate,
    };
  }

  /// Update user statistics after video upload
  Future<void> updateUserStats(
    String userId,
    String displayName,
    int videoCount,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    _userStats.putIfAbsent(
      userId,
      () => _UserStats(userId: userId, displayName: displayName),
    );

    _userStats[userId]!.totalVideos = videoCount;
  }

  /// Update user follower count
  Future<void> updateFollowerCount(String userId, int count) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (_userStats.containsKey(userId)) {
      _userStats[userId]!.followerCount = count;
    }
  }

  /// Get ranking list (internal)
  List<RankedVideo> _getRanking(RankingPeriod period, int limit) {
    final videos = _engagementData.values.map((engagement) {
      final avgRating = engagement.ratings.isNotEmpty
          ? engagement.ratings.reduce((a, b) => a + b) / engagement.ratings.length
          : 0.0;

      final engagementScore =
          (engagement.viewCount * 0.3) + (engagement.likeCount * 1.0) + (engagement.shareCount * 2.0);

      return RankedVideo(
        videoId: engagement.videoId,
        title: 'Video ${engagement.videoId.substring(0, 8)}',
        creatorId: 'creator_${engagement.videoId}',
        viewCount: engagement.viewCount,
        likeCount: engagement.likeCount,
        shareCount: engagement.shareCount,
        averageRating: avgRating,
        engagementScore: engagementScore,
        rank: 0,
        period: period,
        lastUpdated: DateTime.now(),
      );
    }).toList();

    // Sort by engagement score
    videos.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));

    // Assign ranks and return limited results
    for (int i = 0; i < videos.length; i++) {
      videos[i] = videos[i].copyWith(rank: i + 1);
    }

    return videos.take(limit).toList();
  }

  /// Clear all data (for testing)
  void clearData() {
    _engagementData.clear();
    _userStats.clear();
  }
}

/// Internal engagement data storage
class _VideoEngagement {
  final String videoId;
  int viewCount = 0;
  int likeCount = 0;
  int shareCount = 0;
  final List<int> ratings = [];

  _VideoEngagement({required this.videoId});
}

/// Internal user statistics storage
class _UserStats {
  final String userId;
  final String displayName;
  int totalVideos = 0;
  int totalViews = 0;
  int totalLikes = 0;
  int totalShares = 0;
  int followerCount = 0;
  final List<int> ratings = [];

  _UserStats({
    required this.userId,
    required this.displayName,
  });
}
