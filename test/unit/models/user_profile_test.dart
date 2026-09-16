import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('getEngagementRate calculates correctly', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        totalVideos: 10,
        totalViews: 1000,
        totalLikes: 200,
        followerCount: 500,
        followingCount: 100,
        averageRating: 4.5,
        badges: [],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.getEngagementRate(), closeTo(20.0, 0.1));
    });

    test('getEngagementRate returns 0 for zero views', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        totalVideos: 0,
        totalViews: 0,
        totalLikes: 0,
        followerCount: 0,
        followingCount: 0,
        averageRating: 0.0,
        badges: [],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.getEngagementRate(), equals(0.0));
    });

    test('getAverageViewsPerVideo calculates correctly', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        totalVideos: 20,
        totalViews: 10000,
        totalLikes: 500,
        followerCount: 1000,
        followingCount: 200,
        averageRating: 4.5,
        badges: [],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.getAverageViewsPerVideo(), equals(500.0));
    });

    test('isTopCreator returns true for high rating and views', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'TopCreator',
        totalVideos: 50,
        totalViews: 100000,
        totalLikes: 10000,
        followerCount: 10000,
        followingCount: 500,
        averageRating: 4.8,
        badges: [UserBadge.topCreator],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.isTopCreator, isTrue);
    });

    test('isTopCreator returns false for low rating', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        totalVideos: 50,
        totalViews: 100000,
        totalLikes: 5000,
        followerCount: 10000,
        followingCount: 500,
        averageRating: 3.5,
        badges: [],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.isTopCreator, isFalse);
    });

    test('isTopCreator returns false for low views', () {
      final profile = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        totalVideos: 5,
        totalViews: 500,
        totalLikes: 50,
        followerCount: 100,
        followingCount: 50,
        averageRating: 4.8,
        badges: [],
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.isTopCreator, isFalse);
    });

    test('copyWith creates new instance with modified fields', () {
      final original = UserProfile(
        id: 'user1',
        displayName: 'Creator',
        bio: 'My bio',
        totalVideos: 10,
        totalViews: 5000,
        totalLikes: 500,
        followerCount: 1000,
        followingCount: 100,
        averageRating: 4.0,
        badges: [],
        isVerified: false,
        socialLinks: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        isVerified: true,
        followerCount: 2000,
      );

      expect(modified.isVerified, isTrue);
      expect(modified.followerCount, equals(2000));
      expect(modified.id, equals(original.id));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = UserProfile(
        id: 'user1',
        displayName: 'TopCreator',
        bio: 'Animation enthusiast',
        profileImageUrl: 'https://example.com/profile.jpg',
        totalVideos: 50,
        totalViews: 100000,
        totalLikes: 10000,
        followerCount: 5000,
        followingCount: 500,
        averageRating: 4.8,
        badges: [UserBadge.topCreator, UserBadge.verified],
        isVerified: true,
        websiteUrl: 'https://example.com',
        socialLinks: {'twitter': '@creator', 'instagram': '@creator'},
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.displayName, equals(original.displayName));
      expect(restored.isVerified, isTrue);
      expect(restored.badges, hasLength(2));
      expect(restored.totalViews, equals(100000));
    });
  });

  group('FollowRelationship', () {
    test('copyWith preserves relationship data', () {
      final now = DateTime.now();
      final original = FollowRelationship(
        followerId: 'user1',
        followingId: 'user2',
        followedAt: now,
      );

      final modified = original.copyWith();

      expect(modified.followerId, equals(original.followerId));
      expect(modified.followingId, equals(original.followingId));
      expect(modified.followedAt, equals(original.followedAt));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = FollowRelationship(
        followerId: 'user1',
        followingId: 'user2',
        followedAt: now,
      );

      final json = original.toJson();
      final restored = FollowRelationship.fromJson(json);

      expect(restored.followerId, equals(original.followerId));
      expect(restored.followingId, equals(original.followingId));
      expect(restored.followedAt, equals(original.followedAt));
    });
  });

  group('UserBadge Enum', () {
    test('all user badges are defined', () {
      expect(UserBadge.values, hasLength(7));
      expect(UserBadge.values, contains(UserBadge.verified));
      expect(UserBadge.values, contains(UserBadge.topCreator));
      expect(UserBadge.values, contains(UserBadge.trendingSetter));
      expect(UserBadge.values, contains(UserBadge.communityHelper));
      expect(UserBadge.values, contains(UserBadge.earlyAdopter));
      expect(UserBadge.values, contains(UserBadge.milestone100k));
      expect(UserBadge.values, contains(UserBadge.milestone1m));
    });
  });
}
