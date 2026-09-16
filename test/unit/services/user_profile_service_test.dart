import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/services/user_profile_service.dart';

void main() {
  group('UserProfileService', () {
    late UserProfileService service;

    setUp(() {
      service = UserProfileService.instance;
      service.clearData();
    });

    test('singleton returns same instance', () {
      final instance1 = UserProfileService.instance;
      final instance2 = UserProfileService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('createProfile creates new user profile', () async {
      final profile = await service.createProfile(
        userId: 'user1',
        displayName: 'Creator One',
        bio: 'I make videos',
      );

      expect(profile.id, equals('user1'));
      expect(profile.displayName, equals('Creator One'));
      expect(profile.followerCount, equals(0));
      expect(profile.followingCount, equals(0));
    });

    test('getUserProfile returns created profile', () async {
      await service.createProfile(
        userId: 'user1',
        displayName: 'Creator',
      );

      final profile = await service.getUserProfile('user1');

      expect(profile, isNotNull);
      expect(profile!.displayName, equals('Creator'));
    });

    test('getUserProfile returns null for non-existent', () async {
      final profile = await service.getUserProfile('nonexistent');

      expect(profile, isNull);
    });

    test('updateProfile modifies existing profile', () async {
      var profile = await service.createProfile(
        userId: 'user1',
        displayName: 'Creator',
      );

      profile = profile.copyWith(
        bio: 'Updated bio',
        isVerified: true,
      );
      profile = await service.updateProfile(profile);

      expect(profile.bio, equals('Updated bio'));
      expect(profile.isVerified, isTrue);
    });

    test('followUser creates follow relationship', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');

      await service.followUser('user1', 'user2');

      final isFollowing = await service.isFollowing('user1', 'user2');
      expect(isFollowing, isTrue);
    });

    test('followUser updates follower counts', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');

      await service.followUser('user1', 'user2');

      final profile1 = await service.getUserProfile('user1');
      final profile2 = await service.getUserProfile('user2');

      expect(profile1!.followingCount, equals(1));
      expect(profile2!.followerCount, equals(1));
    });

    test('unfollowUser removes follow relationship', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');

      await service.followUser('user1', 'user2');
      await service.unfollowUser('user1', 'user2');

      final isFollowing = await service.isFollowing('user1', 'user2');
      expect(isFollowing, isFalse);
    });

    test('unfollowUser updates follower counts', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');

      await service.followUser('user1', 'user2');
      await service.unfollowUser('user1', 'user2');

      final profile1 = await service.getUserProfile('user1');
      final profile2 = await service.getUserProfile('user2');

      expect(profile1!.followingCount, equals(0));
      expect(profile2!.followerCount, equals(0));
    });

    test('isFollowing returns false for non-existent relationship', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');

      final isFollowing = await service.isFollowing('user1', 'user2');
      expect(isFollowing, isFalse);
    });

    test('getFollowers returns list of followers', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');
      await service.createProfile(userId: 'user3', displayName: 'Creator 3');

      await service.followUser('user2', 'user1');
      await service.followUser('user3', 'user1');

      final followers = await service.getFollowers('user1');

      expect(followers, hasLength(2));
    });

    test('getFollowing returns list of followed users', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');
      await service.createProfile(userId: 'user3', displayName: 'Creator 3');

      await service.followUser('user1', 'user2');
      await service.followUser('user1', 'user3');

      final following = await service.getFollowing('user1');

      expect(following, hasLength(2));
    });

    test('updateBadges adds badges to profile', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator');

      await service.updateBadges('user1', [UserBadge.verified, UserBadge.topCreator]);

      final profile = await service.getUserProfile('user1');
      expect(profile!.badges, hasLength(2));
    });

    test('updateVideoStats updates statistics', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator');

      await service.updateVideoStats(
        'user1',
        totalVideos: 10,
        totalViews: 5000,
        totalLikes: 500,
      );

      final profile = await service.getUserProfile('user1');

      expect(profile!.totalVideos, equals(10));
      expect(profile.totalViews, equals(5000));
      expect(profile.totalLikes, equals(500));
    });

    test('updateAverageRating updates rating', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator');

      await service.updateAverageRating('user1', 4.8);

      final profile = await service.getUserProfile('user1');
      expect(profile!.averageRating, closeTo(4.8, 0.01));
    });

    test('searchUsers finds users by name', () async {
      await service.createProfile(userId: 'user1', displayName: 'John Animator');
      await service.createProfile(userId: 'user2', displayName: 'Jane Video');
      await service.createProfile(userId: 'user3', displayName: 'John Creator');

      final results = await service.searchUsers('John');

      expect(results, hasLength(2));
    });

    test('searchUsers is case-insensitive', () async {
      await service.createProfile(userId: 'user1', displayName: 'CreatorOne');

      final results = await service.searchUsers('creator');

      expect(results, hasLength(1));
    });

    test('getUserProfileWithStats returns complete data', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator');
      await service.updateVideoStats(
        'user1',
        totalVideos: 20,
        totalViews: 10000,
        totalLikes: 1000,
      );

      final stats = await service.getUserProfileWithStats('user1');

      expect(stats['profile'], isNotNull);
      expect(stats['engagementRate'], closeTo(10.0, 0.1));
      expect(stats['averageViewsPerVideo'], equals(500.0));
    });

    test('followUser prevents self-follow', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator');

      await service.followUser('user1', 'user1');

      final isFollowing = await service.isFollowing('user1', 'user1');
      expect(isFollowing, isFalse);
    });

    test('concurrent follows work correctly', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');
      await service.createProfile(userId: 'user3', displayName: 'Creator 3');
      await service.createProfile(userId: 'user4', displayName: 'Creator 4');

      final futures = <Future>[
        service.followUser('user2', 'user1'),
        service.followUser('user3', 'user1'),
        service.followUser('user4', 'user1'),
      ];

      await Future.wait(futures);

      final followers = await service.getFollowers('user1');
      expect(followers, hasLength(3));
    });

    test('getAllProfiles returns all profiles', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');
      await service.createProfile(userId: 'user3', displayName: 'Creator 3');

      final profiles = await service.getAllProfiles();

      expect(profiles, hasLength(3));
    });

    test('multiple follow/unfollow cycles work correctly', () async {
      await service.createProfile(userId: 'user1', displayName: 'Creator 1');
      await service.createProfile(userId: 'user2', displayName: 'Creator 2');

      // First cycle
      await service.followUser('user1', 'user2');
      expect(await service.isFollowing('user1', 'user2'), isTrue);

      // Unfollow
      await service.unfollowUser('user1', 'user2');
      expect(await service.isFollowing('user1', 'user2'), isFalse);

      // Follow again
      await service.followUser('user1', 'user2');
      expect(await service.isFollowing('user1', 'user2'), isTrue);

      final profile2 = await service.getUserProfile('user2');
      expect(profile2!.followerCount, equals(1));
    });
  });
}
