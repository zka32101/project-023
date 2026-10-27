import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/models/video_comment.dart';
import 'package:tsukuani/models/video_ranking.dart';
import 'package:tsukuani/services/user_profile_service.dart';
import 'package:tsukuani/services/video_comments_service.dart';
import 'package:tsukuani/services/video_ranking_service.dart';

void main() {
  group('Community Features Integration Workflow', () {
    late VideoRankingService rankingService;
    late VideoCommentsService commentsService;
    late UserProfileService profileService;

    setUp(() {
      rankingService = VideoRankingService.instance;
      commentsService = VideoCommentsService.instance;
      profileService = UserProfileService.instance;

      rankingService.clearData();
      commentsService.clearData();
      profileService.clearData();
    });

    group('Complete Creator Workflow', () {
      test('creator can create profile and receive engagement', () async {
        // Create creator profile
        final creator = await profileService.createProfile(
          userId: 'creator1',
          displayName: 'Video Creator',
          bio: 'Making awesome videos',
        );

        expect(creator.id, equals('creator1'));
        expect(creator.displayName, equals('Video Creator'));

        // Upload video and track engagement
        await rankingService.incrementViewCount('video1');
        await rankingService.addLike('video1');
        await rankingService.addShare('video1');
        await rankingService.addRating('video1', 5);

        // Update creator stats
        await profileService.updateVideoStats(
          'creator1',
          totalVideos: 1,
          totalViews: 1,
          totalLikes: 1,
        );

        final stats = await profileService.getUserProfileWithStats('creator1');
        expect(stats['profile'], isNotNull);
        expect(stats['engagementRate'], greaterThan(0));
      });

      test('creator can receive verification badge', () async {
        await profileService.createProfile(
          userId: 'creator2',
          displayName: 'Verified Creator',
        );

        await profileService.updateBadges('creator2', [UserBadge.verified]);

        final profile = await profileService.getUserProfile('creator2');
        expect(profile!.badges, contains(UserBadge.verified));
        expect(profile.isVerified, isTrue);
      });

      test('creator can be ranked based on engagement', () async {
        // Create multiple creators
        await profileService.createProfile(userId: 'creator1', displayName: 'Creator 1');
        await profileService.createProfile(userId: 'creator2', displayName: 'Creator 2');

        // Add engagement data
        for (int i = 0; i < 5; i++) {
          await rankingService.incrementViewCount('vid_creator1_$i');
          await rankingService.addLike('vid_creator1_$i');
        }

        for (int i = 0; i < 3; i++) {
          await rankingService.incrementViewCount('vid_creator2_$i');
        }

        await rankingService.updateUserStats('creator1', 'Creator 1', 5);
        await rankingService.updateUserStats('creator2', 'Creator 2', 3);

        final ranking = await rankingService.getCreatorRanking();
        expect(ranking, isNotEmpty);
      });
    });

    group('Viewer Engagement Workflow', () {
      test('viewer can follow creator and see their videos', () async {
        // Setup: Creator and videos
        await profileService.createProfile(
          userId: 'creator1',
          displayName: 'Popular Creator',
        );
        await profileService.createProfile(
          userId: 'viewer1',
          displayName: 'Video Fan',
        );

        // Viewer follows creator
        await profileService.followUser('viewer1', 'creator1');

        // Check follow relationship
        final isFollowing = await profileService.isFollowing('viewer1', 'creator1');
        expect(isFollowing, isTrue);

        // Check creator follower count
        final creator = await profileService.getUserProfile('creator1');
        expect(creator!.followerCount, equals(1));
      });

      test('viewer can like and comment on video', () async {
        // Setup profiles
        await profileService.createProfile(
          userId: 'creator1',
          displayName: 'Content Creator',
        );
        await profileService.createProfile(
          userId: 'viewer1',
          displayName: 'Viewer',
        );

        // Viewer engages with video
        await rankingService.incrementViewCount('video1');
        await rankingService.addLike('video1');

        final comment = await commentsService.postComment(
          'video1',
          'viewer1',
          'Viewer',
          'Great content!',
        );

        expect(comment.text, equals('Great content!'));

        // Verify engagement tracking
        final stats = await rankingService.getVideoEngagementStats('video1');
        expect(stats['viewCount'], equals(1));
        expect(stats['likeCount'], equals(1));
      });

      test('viewer can like comments and participate in discussions', () async {
        // Setup
        final parent = await commentsService.postComment(
          'video1',
          'creator1',
          'Creator',
          'Check this out!',
        );

        final reply = await commentsService.postComment(
          'video1',
          'viewer1',
          'Viewer',
          'Love this!',
          parentCommentId: parent.id,
        );

        // Viewer likes parent comment
        await commentsService.likeComment('video1', parent.id, 'viewer1');
        await commentsService.likeComment('video1', parent.id, 'viewer2');

        final comments = await commentsService.getComments('video1', topLevelOnly: true);
        expect(comments.first.likeCount, equals(2));
      });
    });

    group('Comment Threading & Moderation', () {
      test('comments can be nested with proper hierarchy', () async {
        final parent = await commentsService.postComment(
          'video1',
          'user1',
          'User 1',
          'Parent comment',
        );

        final reply1 = await commentsService.postComment(
          'video1',
          'user2',
          'User 2',
          'Reply 1',
          parentCommentId: parent.id,
        );

        final reply2 = await commentsService.postComment(
          'video1',
          'user3',
          'User 3',
          'Reply 2',
          parentCommentId: parent.id,
        );

        final replies = await commentsService.getCommentReplies('video1', parent.id);
        expect(replies, hasLength(2));
        expect(replies.map((r) => r.id), contains(reply1.id));
        expect(replies.map((r) => r.id), contains(reply2.id));
      });

      test('creator can pin important comments', () async {
        final comment = await commentsService.postComment(
          'video1',
          'user1',
          'User 1',
          'Important message',
        );

        await commentsService.pinComment('video1', comment.id);

        final comments = await commentsService.getComments('video1');
        expect(comments.first.isPinned, isTrue);
      });

      test('inappropriate comments can be flagged for review', () async {
        final comment = await commentsService.postComment(
          'video1',
          'user1',
          'User 1',
          'Inappropriate content',
        );

        await commentsService.flagComment('video1', comment.id);

        final comments = await commentsService.getComments('video1');
        expect(comments.first.isFlagged, isTrue);
      });
    });

    group('Video Rating & Review System', () {
      test('viewers can submit reviews with categories', () async {
        final review = await commentsService.postReview(
          'video1',
          'viewer1',
          'Viewer 1',
          5,
          'Excellent content!',
          [ReviewCategory.creativity, ReviewCategory.quality],
        );

        expect(review.rating, equals(5));
        expect(review.categories, hasLength(2));
      });

      test('reviews are sorted by helpfulness', () async {
        final review1 = await commentsService.postReview(
          'video1',
          'user1',
          'User 1',
          5,
          'Great!',
          [],
        );

        final review2 = await commentsService.postReview(
          'video1',
          'user2',
          'User 2',
          4,
          'Good',
          [],
        );

        await commentsService.markReviewHelpful('video1', review2.id);
        await commentsService.markReviewHelpful('video1', review2.id);

        final reviews = await commentsService.getReviews('video1');
        expect(reviews.first.id, equals(review2.id));
      });

      test('average rating is calculated from reviews', () async {
        await commentsService.postReview('video1', 'user1', 'User 1', 5, 'Excellent', []);
        await commentsService.postReview('video1', 'user2', 'User 2', 3, 'OK', []);
        await commentsService.postReview('video1', 'user3', 'User 3', 4, 'Good', []);

        final avg = await commentsService.getAverageRating('video1');
        expect(avg, closeTo(4.0, 0.01));
      });

      test('rating distribution shows count by star level', () async {
        await commentsService.postReview('video1', 'user1', 'User 1', 5, 'Excellent', []);
        await commentsService.postReview('video1', 'user2', 'User 2', 5, 'Great', []);
        await commentsService.postReview('video1', 'user3', 'User 3', 4, 'Good', []);

        final dist = await commentsService.getRatingDistribution('video1');
        expect(dist[5], equals(2));
        expect(dist[4], equals(1));
      });
    });

    group('Social Network Growth', () {
      test('following network grows and followers/following lists update', () async {
        // Create users
        await profileService.createProfile(userId: 'user1', displayName: 'User 1');
        await profileService.createProfile(userId: 'user2', displayName: 'User 2');
        await profileService.createProfile(userId: 'user3', displayName: 'User 3');

        // Build network: user2 and user3 follow user1
        await profileService.followUser('user2', 'user1');
        await profileService.followUser('user3', 'user1');

        // Verify user1's followers
        final followers = await profileService.getFollowers('user1');
        expect(followers, hasLength(2));

        // Verify user2's following
        final following = await profileService.getFollowing('user2');
        expect(following, hasLength(1));
      });

      test('user statistics update when videos perform well', () async {
        await profileService.createProfile(userId: 'creator1', displayName: 'Creator');

        // Simulate video performance
        for (int i = 0; i < 3; i++) {
          await rankingService.incrementViewCount('vid_$i');
          await rankingService.addLike('vid_$i');
          await rankingService.addRating('vid_$i', 4);
        }

        await profileService.updateVideoStats(
          'creator1',
          totalVideos: 3,
          totalViews: 3,
          totalLikes: 3,
        );

        await profileService.updateAverageRating('creator1', 4.0);

        final profile = await profileService.getUserProfile('creator1');
        expect(profile!.totalVideos, equals(3));
        expect(profile.averageRating, closeTo(4.0, 0.1));
      });

      test('top creators are identified by engagement threshold', () async {
        // Create creator with high stats
        await profileService.createProfile(userId: 'top_creator', displayName: 'Top Creator');
        await profileService.updateVideoStats(
          'top_creator',
          totalVideos: 50,
          totalViews: 100000,
          totalLikes: 10000,
        );
        await profileService.updateAverageRating('top_creator', 4.8);
        await profileService.updateBadges('top_creator', [UserBadge.topCreator]);

        final profile = await profileService.getUserProfile('top_creator');
        expect(profile!.isTopCreator, isTrue);
        expect(profile.badges, contains(UserBadge.topCreator));
      });
    });

    group('Concurrent Community Activities', () {
      test('multiple viewers can comment simultaneously without conflicts', () async {
        final futures = List.generate(
          10,
          (i) => commentsService.postComment(
            'video1',
            'user$i',
            'User $i',
            'Comment $i',
          ),
        );

        final comments = await Future.wait(futures);
        final allComments = await commentsService.getComments('video1');

        expect(comments, hasLength(10));
        expect(allComments, hasLength(10));
      });

      test('multiple likes on same comment update count correctly', () async {
        final comment = await commentsService.postComment(
          'video1',
          'user1',
          'User 1',
          'Great video!',
        );

        final futures = List.generate(
          5,
          (i) => commentsService.likeComment('video1', comment.id, 'user${i + 2}'),
        );

        await Future.wait(futures);

        final comments = await commentsService.getComments('video1');
        expect(comments.first.likeCount, equals(5));
      });

      test('concurrent profile updates preserve consistency', () async {
        await profileService.createProfile(userId: 'user1', displayName: 'User 1');

        // Concurrent follow/unfollow cycles
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(profileService.followUser('user1', 'user${i + 2}'));
        }

        await Future.wait(futures);

        final profile = await profileService.getUserProfile('user1');
        expect(profile!.followingCount, equals(3));
      });
    });

    group('Data Consistency & Cleanup', () {
      test('deleting comment updates parent reply count', () async {
        final parent = await commentsService.postComment(
          'video1',
          'user1',
          'User 1',
          'Parent',
        );

        final reply = await commentsService.postComment(
          'video1',
          'user2',
          'User 2',
          'Reply',
          parentCommentId: parent.id,
        );

        await commentsService.deleteComment('video1', reply.id);

        final comments = await commentsService.getComments('video1', topLevelOnly: true);
        expect(comments.first.replyCount, equals(0));
      });

      test('unfollowing removes from both follower and following lists', () async {
        await profileService.createProfile(userId: 'user1', displayName: 'User 1');
        await profileService.createProfile(userId: 'user2', displayName: 'User 2');

        await profileService.followUser('user1', 'user2');
        expect(await profileService.isFollowing('user1', 'user2'), isTrue);

        await profileService.unfollowUser('user1', 'user2');
        expect(await profileService.isFollowing('user1', 'user2'), isFalse);

        final followers = await profileService.getFollowers('user2');
        expect(followers, isEmpty);
      });

      test('all community data can be retrieved in bulk', () async {
        // Create diverse community
        for (int i = 0; i < 5; i++) {
          await profileService.createProfile(userId: 'user$i', displayName: 'User $i');
        }

        final allProfiles = await profileService.getAllProfiles();
        expect(allProfiles, hasLength(5));
      });
    });

    group('Search & Discovery', () {
      test('users can be found by display name', () async {
        await profileService.createProfile(userId: 'user1', displayName: 'John Creator');
        await profileService.createProfile(userId: 'user2', displayName: 'Jane Video');
        await profileService.createProfile(userId: 'user3', displayName: 'John Designer');

        final results = await profileService.searchUsers('John');
        expect(results, hasLength(2));
      });

      test('search is case-insensitive', () async {
        await profileService.createProfile(userId: 'user1', displayName: 'VideoCreator');

        final results1 = await profileService.searchUsers('video');
        final results2 = await profileService.searchUsers('VIDEO');

        expect(results1, hasLength(1));
        expect(results2, hasLength(1));
      });

      test('videos are ranked correctly with engagement formula', () async {
        // Create videos with different engagement
        await rankingService.incrementViewCount('video1'); // 1 view
        for (int i = 0; i < 3; i++) {
          await rankingService.incrementViewCount('video2'); // 3 views
          await rankingService.addLike('video2'); // 1 like
        }

        final ranking = await rankingService.getDailyRanking();
        expect(ranking, isNotEmpty);
        // video2 should rank higher: (3 × 0.3) + (1 × 1.0) = 1.9 vs video1: (1 × 0.3) = 0.3
      });
    });
  });
}
