/// Service for managing user profiles and social connections

import 'package:tsukuani/models/user_profile.dart';

/// Service for managing user profiles and follow relationships
class UserProfileService {
  static UserProfileService? _instance;

  /// Storage for user profiles by ID
  final Map<String, UserProfile> _profiles = {};

  /// Storage for follow relationships
  final Map<String, Set<String>> _followers = {}; // userId -> Set<followerIds>
  final Map<String, Set<String>> _following = {}; // userId -> Set<followingIds>

  /// Singleton instance
  static UserProfileService get instance {
    _instance ??= UserProfileService._();
    return _instance;
  }

  UserProfileService._();

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _profiles[userId];
  }

  /// Create or update user profile
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final updatedProfile = profile.copyWith(
      updatedAt: now,
    );

    _profiles[profile.id] = updatedProfile;
    return updatedProfile;
  }

  /// Create a new user profile
  Future<UserProfile> createProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      displayName: displayName,
      bio: bio,
      profileImageUrl: profileImageUrl,
      followerCount: 0,
      followingCount: 0,
      totalVideos: 0,
      totalViews: 0,
      totalLikes: 0,
      averageRating: 0.0,
      badges: [],
      socialLinks: {},
      createdAt: now,
      updatedAt: now,
    );

    _profiles[userId] = profile;
    _followers.putIfAbsent(userId, () => {});
    _following.putIfAbsent(userId, () => {});

    return profile;
  }

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (followerId == followingId) return;

    _followers.putIfAbsent(followingId, () => {});
    _following.putIfAbsent(followerId, () => {});

    // Add follow relationship
    _followers[followingId]!.add(followerId);
    _following[followerId]!.add(followingId);

    // Update follower/following counts
    if (_profiles.containsKey(followingId)) {
      final profile = _profiles[followingId]!;
      _profiles[followingId] = profile.copyWith(
        followerCount: _followers[followingId]!.length,
      );
    }

    if (_profiles.containsKey(followerId)) {
      final profile = _profiles[followerId]!;
      _profiles[followerId] = profile.copyWith(
        followingCount: _following[followerId]!.length,
      );
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (followerId == followingId) return;

    if (_followers.containsKey(followingId)) {
      _followers[followingId]!.remove(followerId);
    }

    if (_following.containsKey(followerId)) {
      _following[followerId]!.remove(followingId);
    }

    // Update follower/following counts
    if (_profiles.containsKey(followingId)) {
      final profile = _profiles[followingId]!;
      _profiles[followingId] = profile.copyWith(
        followerCount: _followers[followingId]?.length ?? 0,
      );
    }

    if (_profiles.containsKey(followerId)) {
      final profile = _profiles[followerId]!;
      _profiles[followerId] = profile.copyWith(
        followingCount: _following[followerId]?.length ?? 0,
      );
    }
  }

  /// Check if user follows another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_following.containsKey(followerId)) return false;
    return _following[followerId]!.contains(followingId);
  }

  /// Get list of followers
  Future<List<UserProfile>> getFollowers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_followers.containsKey(userId)) return [];

    final followerIds = _followers[userId]!.toList();
    final followers = <UserProfile>[];

    for (final followerId in followerIds) {
      final profile = _profiles[followerId];
      if (profile != null) {
        followers.add(profile);
      }
    }

    return followers;
  }

  /// Get list of users being followed
  Future<List<UserProfile>> getFollowing(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_following.containsKey(userId)) return [];

    final followingIds = _following[userId]!.toList();
    final following = <UserProfile>[];

    for (final followingId in followingIds) {
      final profile = _profiles[followingId];
      if (profile != null) {
        following.add(profile);
      }
    }

    return following;
  }

  /// Update user badges
  Future<void> updateBadges(String userId, List<UserBadge> badges) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_profiles.containsKey(userId)) return;

    final profile = _profiles[userId]!;
    _profiles[userId] = profile.copyWith(badges: badges);
  }

  /// Update user video statistics
  Future<void> updateVideoStats(
    String userId, {
    int? totalVideos,
    int? totalViews,
    int? totalLikes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_profiles.containsKey(userId)) return;

    final profile = _profiles[userId]!;
    _profiles[userId] = profile.copyWith(
      totalVideos: totalVideos ?? profile.totalVideos,
      totalViews: totalViews ?? profile.totalViews,
      totalLikes: totalLikes ?? profile.totalLikes,
    );
  }

  /// Update user average rating
  Future<void> updateAverageRating(String userId, double rating) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_profiles.containsKey(userId)) return;

    final profile = _profiles[userId]!;
    _profiles[userId] = profile.copyWith(averageRating: rating);
  }

  /// Search users by display name
  Future<List<UserProfile>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final results = _profiles.values
        .where((p) => p.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return results;
  }

  /// Get user profile including statistics
  Future<Map<String, dynamic>> getUserProfileWithStats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final profile = _profiles[userId];
    if (profile == null) return {};

    return {
      'profile': profile,
      'followerCount': _followers[userId]?.length ?? 0,
      'followingCount': _following[userId]?.length ?? 0,
      'engagementRate': profile.getEngagementRate(),
      'averageViewsPerVideo': profile.getAverageViewsPerVideo(),
      'isTopCreator': profile.isTopCreator,
    };
  }

  /// Get all profiles (for testing/admin)
  Future<List<UserProfile>> getAllProfiles() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _profiles.values.toList();
  }

  /// Clear all data (for testing)
  void clearData() {
    _profiles.clear();
    _followers.clear();
    _following.clear();
  }
}
