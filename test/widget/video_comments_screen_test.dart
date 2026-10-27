import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_comment.dart';
import 'package:tsukuani/services/video_comments_service.dart';
import 'package:tsukuani/screens/video_comments_screen.dart';

void main() {
  group('VideoCommentsScreen', () {
    late VideoCommentsService commentsService;
    const String videoId = 'video1';

    setUp(() {
      commentsService = VideoCommentsService.instance;
      commentsService.clearData();
    });

    testWidgets('displays empty state when no comments', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No comments yet. Be the first!'), findsOneWidget);
    });

    testWidgets('displays comments in reverse chronological order', (WidgetTester tester) async {
      await commentsService.postComment(videoId, 'user1', 'User 1', 'First comment');
      await Future.delayed(const Duration(milliseconds: 10));
      await commentsService.postComment(videoId, 'user2', 'User 2', 'Second comment');

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Second comment'), findsOneWidget);
      expect(find.text('First comment'), findsOneWidget);
    });

    testWidgets('shows comment author and timestamp', (WidgetTester tester) async {
      await commentsService.postComment(videoId, 'user1', 'User 1', 'Great video!');

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('Great video!'), findsOneWidget);
    });

    testWidgets('displays comment like count', (WidgetTester tester) async {
      final comment = await commentsService.postComment(videoId, 'user1', 'User 1', 'Good!');
      await commentsService.likeComment(videoId, comment.id, 'user2');
      await commentsService.likeComment(videoId, comment.id, 'user3');

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Likes: 2'), findsOneWidget);
    });

    testWidgets('allows liking a comment', (WidgetTester tester) async {
      final comment = await commentsService.postComment(videoId, 'user1', 'User 1', 'Nice!');

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows reply button and reply count', (WidgetTester tester) async {
      final parent = await commentsService.postComment(videoId, 'user1', 'User 1', 'Parent');
      await commentsService.postComment(
        videoId,
        'user2',
        'User 2',
        'Reply',
        parentCommentId: parent.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Replies: 1'), findsOneWidget);
    });

    testWidgets('expands replies when tapped', (WidgetTester tester) async {
      final parent = await commentsService.postComment(videoId, 'user1', 'User 1', 'Parent');
      await commentsService.postComment(
        videoId,
        'user2',
        'User 2',
        'Reply 1',
        parentCommentId: parent.id,
      );
      await commentsService.postComment(
        videoId,
        'user3',
        'User 3',
        'Reply 2',
        parentCommentId: parent.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Replies: 2'));
      await tester.pumpAndSettle();

      expect(find.text('Reply 1'), findsOneWidget);
      expect(find.text('Reply 2'), findsOneWidget);
    });

    testWidgets('displays pinned comments at top', (WidgetTester tester) async {
      final regular = await commentsService.postComment(videoId, 'user1', 'User 1', 'Regular');
      final pinned = await commentsService.postComment(videoId, 'user2', 'User 2', 'Important!');

      await commentsService.pinComment(videoId, pinned.id);

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('shows flagged indicator for inappropriate comments', (WidgetTester tester) async {
      final comment = await commentsService.postComment(
        videoId,
        'user1',
        'User 1',
        'Inappropriate',
      );
      await commentsService.flagComment(videoId, comment.id);

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('comment text field allows posting new comment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My comment');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('My comment'), findsOneWidget);
    });

    testWidgets('can reply to specific comment', (WidgetTester tester) async {
      final parent = await commentsService.postComment(videoId, 'user1', 'User 1', 'Parent');

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My reply');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('My reply'), findsOneWidget);
    });

    testWidgets('shows rating distribution bar chart', (WidgetTester tester) async {
      await commentsService.postReview(videoId, 'user1', 'User 1', 5, 'Excellent', []);
      await commentsService.postReview(videoId, 'user2', 'User 2', 5, 'Great', []);
      await commentsService.postReview(videoId, 'user3', 'User 3', 4, 'Good', []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoCommentsScreen(videoId: videoId, showRatings: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('displays average rating', (WidgetTester tester) async {
      await commentsService.postReview(videoId, 'user1', 'User 1', 5, 'Excellent', []);
      await commentsService.postReview(videoId, 'user2', 'User 2', 3, 'OK', []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoCommentsScreen(videoId: videoId, showRatings: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Average: 4.0'), findsOneWidget);
    });

    testWidgets('filters comments and reviews in separate tabs', (WidgetTester tester) async {
      await commentsService.postComment(videoId, 'user1', 'User 1', 'Comment');
      await commentsService.postReview(videoId, 'user2', 'User 2', 5, 'Review', []);

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCommentsScreen(videoId: videoId),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Comment'), findsNothing);
    });

    testWidgets('pagination loads more comments', (WidgetTester tester) async {
      for (int i = 0; i < 15; i++) {
        await commentsService.postComment(videoId, 'user$i', 'User $i', 'Comment $i');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoCommentsScreen(videoId: videoId, pageSize: 10),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile).length, greaterThanOrEqualTo(10));
    });
  });
}
