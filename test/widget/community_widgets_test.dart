import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/models/video_comment.dart';
import 'package:tsukuani/widgets/badge_display.dart';
import 'package:tsukuani/widgets/engagement_metrics.dart';
import 'package:tsukuani/widgets/rating_display.dart';
import 'package:tsukuani/widgets/comment_card.dart';
import 'package:tsukuani/widgets/user_card.dart';

void main() {
  group('Community Widgets', () {
    group('BadgeDisplay Widget', () {
      testWidgets('displays single badge correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
          home: BadgeDisplay(badges: [UserBadge.verified]),
        ),
        );

        expect(find.byIcon(Icons.verified), findsOneWidget);
        expect(find.text('Verified'), findsOneWidget);
      });

      testWidgets('displays multiple badges', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BadgeDisplay(
              badges: [
                UserBadge.verified,
                UserBadge.topCreator,
                UserBadge.trendingSetter,
              ],
            ),
          ),
        );

        expect(find.byType(Chip), findsWidgets);
        expect(find.text('Verified'), findsOneWidget);
        expect(find.text('Top Creator'), findsOneWidget);
        expect(find.text('Trending Setter'), findsOneWidget);
      });

      testWidgets('handles empty badge list', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
          home: BadgeDisplay(badges: []),
        ),
        );

        expect(find.byType(Chip), findsNothing);
      });

      testWidgets('badge tooltips show on hover', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
          home: BadgeDisplay(badges: [UserBadge.milestone100k]),
        ),
        );

        await tester.pumpAndSettle();
        expect(find.text('100K Milestone'), findsOneWidget);
      });
    });

    group('EngagementMetrics Widget', () {
      testWidgets('displays all engagement metrics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EngagementMetrics(
              views: 1000,
              likes: 200,
              shares: 50,
              comments: 75,
              engagementRate: 32.5,
            ),
          ),
        );

        expect(find.text('1.0K'), findsOneWidget);
        expect(find.text('200'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
        expect(find.text('75'), findsOneWidget);
        expect(find.text('32.5%'), findsOneWidget);
      });

      testWidgets('formats large numbers with K/M suffixes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EngagementMetrics(
              views: 100000,
              likes: 5000,
              shares: 500,
              comments: 1000,
              engagementRate: 10.0,
            ),
          ),
        );

        expect(find.text('100.0K'), findsOneWidget);
        expect(find.text('5.0K'), findsOneWidget);
      });

      testWidgets('shows engagement trend arrows', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EngagementMetrics(
              views: 1000,
              likes: 200,
              shares: 50,
              comments: 75,
              engagementRate: 32.5,
              trendUp: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      });

      testWidgets('metric icons display correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EngagementMetrics(
              views: 1000,
              likes: 200,
              shares: 50,
              comments: 75,
              engagementRate: 32.5,
            ),
          ),
        );

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      });
    });

    group('RatingDisplay Widget', () {
      testWidgets('displays 5 stars rating', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RatingDisplay(rating: 5.0),
          ),
        );

        expect(find.text('★★★★★'), findsOneWidget);
      });

      testWidgets('displays 3.5 stars rating with half star', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RatingDisplay(rating: 3.5, showHalfStars: true),
          ),
        );

        expect(find.text('★★★✩☆'), findsOneWidget);
      });

      testWidgets('displays zero rating', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RatingDisplay(rating: 0.0),
          ),
        );

        expect(find.text('☆☆☆☆☆'), findsOneWidget);
      });

      testWidgets('shows rating count and average', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RatingDisplay(
              rating: 4.5,
              count: 120,
              showCount: true,
            ),
          ),
        );

        expect(find.text('4.5'), findsOneWidget);
        expect(find.text('(120)'), findsOneWidget);
      });

      testWidgets('responds to tap for interactive rating', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RatingDisplay(
              rating: 3.0,
              onRatingChanged: (rating) {},
              interactive: true,
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector).at(4));
        await tester.pumpAndSettle();

        // Interactive rating updated
      });
    });

    group('CommentCard Widget', () {
      testWidgets('displays comment content', (WidgetTester tester) async {
        final comment = VideoComment(
          id: 'c1',
          videoId: 'v1',
          userId: 'u1',
          userDisplayName: 'User',
          text: 'Great video!',
          likeCount: 5,
          replyCount: 2,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
          home: CommentCard(comment: comment),
        ),
        );

        expect(find.text('User'), findsOneWidget);
        expect(find.text('Great video!'), findsOneWidget);
        expect(find.text('Likes: 5'), findsOneWidget);
      });

      testWidgets('shows reply count and expandable replies', (WidgetTester tester) async {
        final comment = VideoComment(
          id: 'c1',
          videoId: 'v1',
          userId: 'u1',
          userDisplayName: 'User',
          text: 'Parent comment',
          likeCount: 0,
          replyCount: 3,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CommentCard(comment: comment, onExpand: () {}),
          ),
        );

        expect(find.text('Replies: 3'), findsOneWidget);
        expect(find.byIcon(Icons.comment), findsOneWidget);
      });

      testWidgets('displays like button', (WidgetTester tester) async {
        final comment = VideoComment(
          id: 'c1',
          videoId: 'v1',
          userId: 'u1',
          userDisplayName: 'User',
          text: 'Nice!',
          likeCount: 10,
          replyCount: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CommentCard(
              comment: comment,
              onLike: () {},
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('shows pinned indicator', (WidgetTester tester) async {
        final comment = VideoComment(
          id: 'c1',
          videoId: 'v1',
          userId: 'u1',
          userDisplayName: 'User',
          text: 'Important!',
          likeCount: 0,
          replyCount: 0,
          createdAt: DateTime.now(),
          isPinned: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CommentCard(comment: comment),
          ),
        );

        expect(find.byIcon(Icons.push_pin), findsOneWidget);
      });
    });

    group('UserCard Widget', () {
      testWidgets('displays user profile summary', (WidgetTester tester) async {
        final profile = UserProfile(
          id: 'u1',
          displayName: 'Creator',
          totalVideos: 10,
          totalViews: 5000,
          totalLikes: 500,
          followerCount: 100,
          followingCount: 50,
          averageRating: 4.5,
          badges: [UserBadge.verified],
          socialLinks: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: UserCard(profile: profile),
          ),
        );

        expect(find.text('Creator'), findsOneWidget);
        expect(find.text('100 followers'), findsOneWidget);
        expect(find.byIcon(Icons.verified), findsOneWidget);
      });

      testWidgets('shows follow button', (WidgetTester tester) async {
        final profile = UserProfile(
          id: 'u1',
          displayName: 'Creator',
          totalVideos: 10,
          totalViews: 5000,
          totalLikes: 500,
          followerCount: 100,
          followingCount: 50,
          averageRating: 4.5,
          badges: [],
          socialLinks: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: UserCard(
              profile: profile,
              onFollowPressed: () {},
              isFollowing: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('displays statistics', (WidgetTester tester) async {
        final profile = UserProfile(
          id: 'u1',
          displayName: 'Creator',
          totalVideos: 25,
          totalViews: 50000,
          totalLikes: 5000,
          followerCount: 500,
          followingCount: 100,
          averageRating: 4.8,
          badges: [UserBadge.topCreator],
          socialLinks: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: UserCard(profile: profile),
          ),
        );

        expect(find.text('25'), findsOneWidget);
        expect(find.text('50K'), findsOneWidget);
      });

      testWidgets('responsive layout', (WidgetTester tester) async {
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        tester.binding.window.physicalSizeTestValue = const Size(400, 600);

        final profile = UserProfile(
          id: 'u1',
          displayName: 'Creator',
          totalVideos: 10,
          totalViews: 5000,
          totalLikes: 500,
          followerCount: 100,
          followingCount: 50,
          averageRating: 4.5,
          badges: [],
          socialLinks: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: UserCard(profile: profile),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}
