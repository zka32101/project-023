import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/services/user_profile_service.dart';
import 'package:tsukuani/screens/user_profile_screen.dart';

void main() {
  group('UserProfileScreen', () {
    late UserProfileService profileService;
    const String userId = 'user1';

    setUp(() {
      profileService = UserProfileService.instance;
      profileService.clearData();
    });

    testWidgets('displays user profile information', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Video Creator',
        bio: 'Making awesome videos',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Video Creator'), findsOneWidget);
      expect(find.text('Making awesome videos'), findsOneWidget);
    });

    testWidgets('shows profile image', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Creator',
        profileImageUrl: 'https://example.com/profile.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('displays follower and following counts', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.createProfile(userId: 'user2', displayName: 'User 2');
      await profileService.createProfile(userId: 'user3', displayName: 'User 3');

      await profileService.followUser('user2', userId);
      await profileService.followUser('user3', userId);
      await profileService.followUser(userId, 'user2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Followers: 2'), findsOneWidget);
      expect(find.text('Following: 1'), findsOneWidget);
    });

    testWidgets('shows video statistics', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateVideoStats(
        userId,
        totalVideos: 10,
        totalViews: 5000,
        totalLikes: 500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
      expect(find.text('5.0K'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('0.5K'), findsOneWidget);
    });

    testWidgets('displays average rating', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateAverageRating(userId, 4.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('★★★★☆'), findsOneWidget);
    });

    testWidgets('shows achievement badges', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateBadges(
        userId,
        [UserBadge.verified, UserBadge.topCreator],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified), findsWidgets);
      expect(find.text('Top Creator'), findsOneWidget);
    });

    testWidgets('displays social links', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Creator',
        socialLinks: {'twitter': '@creator', 'instagram': '@creator'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('@creator'), findsWidgets);
    });

    testWidgets('follow button is visible and functional', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId, currentUserId: 'current_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add_disabled), findsOneWidget);
    });

    testWidgets('unfollow button appears when already following', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.createProfile(userId: 'current_user', displayName: 'Me');
      await profileService.followUser('current_user', userId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId, currentUserId: 'current_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add_disabled), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_add_disabled));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('displays engagement rate', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateVideoStats(
        userId,
        totalVideos: 10,
        totalViews: 1000,
        totalLikes: 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Engagement: 20.0%'), findsOneWidget);
    });

    testWidgets('shows average views per video', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateVideoStats(
        userId,
        totalVideos: 20,
        totalViews: 10000,
        totalLikes: 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Avg Views/Video: 500.0'), findsOneWidget);
    });

    testWidgets('displays verification status', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Creator',
        isVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('shows website link', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Creator',
        websiteUrl: 'https://example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('displays creator videos in tab', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.updateVideoStats(
        userId,
        totalVideos: 5,
        totalViews: 1000,
        totalLikes: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId, showVideosTab: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows followers list in dedicated screen', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');
      await profileService.createProfile(userId: 'follower1', displayName: 'Follower 1');
      await profileService.createProfile(userId: 'follower2', displayName: 'Follower 2');

      await profileService.followUser('follower1', userId);
      await profileService.followUser('follower2', userId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Followers: 2'));
      await tester.pumpAndSettle();

      expect(find.text('Follower 1'), findsOneWidget);
      expect(find.text('Follower 2'), findsOneWidget);
    });

    testWidgets('biography is editable for own profile', (WidgetTester tester) async {
      await profileService.createProfile(
        userId: userId,
        displayName: 'Me',
        bio: 'Old bio',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId, isOwnProfile: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New bio');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('New bio'), findsOneWidget);
    });

    testWidgets('responsive layout on different screen sizes', (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await profileService.createProfile(userId: userId, displayName: 'Creator');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tab system for profile sections', (WidgetTester tester) async {
      await profileService.createProfile(userId: userId, displayName: 'Creator');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(userId: userId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
    });
  });
}
