/// Video ranking models for engagement tracking

/// Represents a video with ranking metrics
class RankedVideo {
  /// Video ID
  final String videoId;

  /// Video title/display name
  final String title;

  /// Creator user ID
  final String creatorId;

  /// Number of views
  final int viewCount;

  /// Number of likes
  final int likeCount;

  /// Number of shares
  final int shareCount;

  /// Average rating (0.0 to 5.0)
  final double averageRating;

  /// Total engagement score
  final double engagementScore;

  /// Rank position (1st, 2nd, etc.)
  final int rank;

  /// Period type (daily, weekly, monthly)
  final RankingPeriod period;

  /// Last updated timestamp
  final DateTime lastUpdated;

  RankedVideo({
    required this.videoId,
    required this.title,
    required this.creatorId,
    required this.viewCount,
    required this.likeCount,
    required this.shareCount,
    required this.averageRating,
    required this.engagementScore,
    required this.rank,
    required this.period,
    required this.lastUpdated,
  });

  /// Get engagement rate (engagement / views)
  double getEngagementRate() {
    return viewCount > 0 ? ((likeCount + shareCount) / viewCount) * 100 : 0.0;
  }

  /// Create copy with modified fields
  RankedVideo copyWith({
    String? videoId,
    String? title,
    String? creatorId,
    int? viewCount,
    int? likeCount,
    int? shareCount,
    double? averageRating,
    double? engagementScore,
    int? rank,
    RankingPeriod? period,
    DateTime? lastUpdated,
  }) {
    return RankedVideo(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      creatorId: creatorId ?? this.creatorId,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      averageRating: averageRating ?? this.averageRating,
      engagementScore: engagementScore ?? this.engagementScore,
      rank: rank ?? this.rank,
      period: period ?? this.period,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'creatorId': creatorId,
    'viewCount': viewCount,
    'likeCount': likeCount,
    'shareCount': shareCount,
    'averageRating': averageRating,
    'engagementScore': engagementScore,
    'rank': rank,
    'period': period.name,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Create from JSON
  factory RankedVideo.fromJson(Map<String, dynamic> json) => RankedVideo(
    videoId: json['videoId'] as String,
    title: json['title'] as String,
    creatorId: json['creatorId'] as String,
    viewCount: json['viewCount'] as int,
    likeCount: json['likeCount'] as int,
    shareCount: json['shareCount'] as int,
    averageRating: (json['averageRating'] as num).toDouble(),
    engagementScore: (json['engagementScore'] as num).toDouble(),
    rank: json['rank'] as int,
    period: RankingPeriod.values.byName(json['period'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  @override
  String toString() => 'RankedVideo($rank. $title, $engagementScore points)';
}

/// Ranking period types
enum RankingPeriod {
  daily,
  weekly,
  monthly,
}

/// Represents user ranking/creator stats
class UserRanking {
  /// User ID
  final String userId;

  /// User display name
  final String displayName;

  /// Total videos
  final int totalVideos;

  /// Total views across all videos
  final int totalViews;

  /// Total likes received
  final int totalLikes;

  /// Total shares
  final int totalShares;

  /// Creator rank position
  final int rank;

  /// Average rating given by viewers
  final double averageRating;

  /// Total followers
  final int followerCount;

  /// Profile image URL
  final String? profileImageUrl;

  /// Last updated timestamp
  final DateTime lastUpdated;

  UserRanking({
    required this.userId,
    required this.displayName,
    required this.totalVideos,
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.rank,
    required this.averageRating,
    required this.followerCount,
    this.profileImageUrl,
    required this.lastUpdated,
  });

  /// Get average views per video
  double getAverageViewsPerVideo() {
    return totalVideos > 0 ? totalViews / totalVideos : 0.0;
  }

  /// Get average engagement per video
  double getAverageEngagementPerVideo() {
    return totalVideos > 0 ? (totalLikes + totalShares) / totalVideos : 0.0;
  }

  /// Create copy with modified fields
  UserRanking copyWith({
    String? userId,
    String? displayName,
    int? totalVideos,
    int? totalViews,
    int? totalLikes,
    int? totalShares,
    int? rank,
    double? averageRating,
    int? followerCount,
    String? profileImageUrl,
    DateTime? lastUpdated,
  }) {
    return UserRanking(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalVideos: totalVideos ?? this.totalVideos,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalShares: totalShares ?? this.totalShares,
      rank: rank ?? this.rank,
      averageRating: averageRating ?? this.averageRating,
      followerCount: followerCount ?? this.followerCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'totalVideos': totalVideos,
    'totalViews': totalViews,
    'totalLikes': totalLikes,
    'totalShares': totalShares,
    'rank': rank,
    'averageRating': averageRating,
    'followerCount': followerCount,
    'profileImageUrl': profileImageUrl,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Create from JSON
  factory UserRanking.fromJson(Map<String, dynamic> json) => UserRanking(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    totalVideos: json['totalVideos'] as int,
    totalViews: json['totalViews'] as int,
    totalLikes: json['totalLikes'] as int,
    totalShares: json['totalShares'] as int,
    rank: json['rank'] as int,
    averageRating: (json['averageRating'] as num).toDouble(),
    followerCount: json['followerCount'] as int,
    profileImageUrl: json['profileImageUrl'] as String?,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  @override
  String toString() => 'UserRanking($rank. $displayName, $totalViews views)';
}
