/// User profile models for creator management

/// Represents a user profile in the community
class UserProfile {
  /// Unique user ID
  final String id;

  /// User's display name
  final String displayName;

  /// User's bio/description
  final String? bio;

  /// Profile image URL
  final String? profileImageUrl;

  /// Banner/cover image URL
  final String? bannerImageUrl;

  /// Total followers
  final int followerCount;

  /// Number of users following this user
  final int followingCount;

  /// Total videos created
  final int totalVideos;

  /// Total views across all videos
  final int totalViews;

  /// Total likes received
  final int totalLikes;

  /// Average rating from reviews
  final double averageRating;

  /// User badges/achievements
  final List<UserBadge> badges;

  /// Whether user is verified
  final bool isVerified;

  /// User's website/social link
  final String? websiteUrl;

  /// User's social media handles
  final Map<String, String> socialLinks;

  /// Account created timestamp
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    required this.followerCount,
    required this.followingCount,
    required this.totalVideos,
    required this.totalViews,
    required this.totalLikes,
    required this.averageRating,
    required this.badges,
    this.isVerified = false,
    this.websiteUrl,
    required this.socialLinks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get user engagement rate
  double getEngagementRate() {
    return totalViews > 0 ? (totalLikes / totalViews) * 100 : 0.0;
  }

  /// Get average views per video
  double getAverageViewsPerVideo() {
    return totalVideos > 0 ? totalViews / totalVideos : 0.0;
  }

  /// Check if user is top creator (rating >= 4.5 and 1000+ views)
  bool get isTopCreator => averageRating >= 4.5 && totalViews >= 1000;

  /// Create copy with modified fields
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    String? bannerImageUrl,
    int? followerCount,
    int? followingCount,
    int? totalVideos,
    int? totalViews,
    int? totalLikes,
    double? averageRating,
    List<UserBadge>? badges,
    bool? isVerified,
    String? websiteUrl,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      totalVideos: totalVideos ?? this.totalVideos,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      averageRating: averageRating ?? this.averageRating,
      badges: badges ?? this.badges,
      isVerified: isVerified ?? this.isVerified,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'bio': bio,
    'profileImageUrl': profileImageUrl,
    'bannerImageUrl': bannerImageUrl,
    'followerCount': followerCount,
    'followingCount': followingCount,
    'totalVideos': totalVideos,
    'totalViews': totalViews,
    'totalLikes': totalLikes,
    'averageRating': averageRating,
    'badges': badges.map((b) => b.name).toList(),
    'isVerified': isVerified,
    'websiteUrl': websiteUrl,
    'socialLinks': socialLinks,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    bio: json['bio'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    bannerImageUrl: json['bannerImageUrl'] as String?,
    followerCount: json['followerCount'] as int,
    followingCount: json['followingCount'] as int,
    totalVideos: json['totalVideos'] as int,
    totalViews: json['totalViews'] as int,
    totalLikes: json['totalLikes'] as int,
    averageRating: (json['averageRating'] as num).toDouble(),
    badges: (json['badges'] as List<dynamic>?)
            ?.map((b) => UserBadge.values.byName(b as String))
            .toList() ??
        [],
    isVerified: json['isVerified'] as bool? ?? false,
    websiteUrl: json['websiteUrl'] as String?,
    socialLinks: Map<String, String>.from(json['socialLinks'] as Map? ?? {}),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  String toString() => 'UserProfile($displayName, $totalViews views, $followerCount followers)';
}

/// User badges/achievements
enum UserBadge {
  verified,
  topCreator,
  trendingSetter,
  communityHelper,
  earlyAdopter,
  milestone100k,
  milestone1m,
}

/// Represents a follow relationship
class FollowRelationship {
  /// Follower user ID
  final String followerId;

  /// User being followed
  final String followingId;

  /// Timestamp of follow
  final DateTime followedAt;

  FollowRelationship({
    required this.followerId,
    required this.followingId,
    required this.followedAt,
  });

  /// Create copy with modified fields
  FollowRelationship copyWith({
    String? followerId,
    String? followingId,
    DateTime? followedAt,
  }) {
    return FollowRelationship(
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'followerId': followerId,
    'followingId': followingId,
    'followedAt': followedAt.toIso8601String(),
  };

  /// Create from JSON
  factory FollowRelationship.fromJson(Map<String, dynamic> json) =>
      FollowRelationship(
        followerId: json['followerId'] as String,
        followingId: json['followingId'] as String,
        followedAt: DateTime.parse(json['followedAt'] as String),
      );

  @override
  String toString() => 'FollowRelationship($followerId follows $followingId)';
}
