import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_comment.dart';
import 'package:tsukuani/services/video_comments_service.dart';

void main() {
  group('VideoCommentsService', () {
    late VideoCommentsService service;

    setUp(() {
      service = VideoCommentsService.instance;
      service.clearData();
    });

    test('singleton returns same instance', () {
      final instance1 = VideoCommentsService.instance;
      final instance2 = VideoCommentsService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('postComment creates comment successfully', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      expect(comment.videoId, equals('video1'));
      expect(comment.text, equals('Great video!'));
      expect(comment.likeCount, equals(0));
    });

    test('postComment with parent creates reply', () async {
      final parent = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      final reply = await service.postComment(
        'video1',
        'user2',
        'User Two',
        'Thanks!',
        parentCommentId: parent.id,
      );

      expect(reply.isReply, isTrue);
      expect(reply.parentCommentId, equals(parent.id));
    });

    test('postComment increments parent reply count', () async {
      final parent = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      await service.postComment(
        'video1',
        'user2',
        'User Two',
        'Thanks!',
        parentCommentId: parent.id,
      );

      final comments = await service.getComments('video1', topLevelOnly: true);
      expect(comments.first.replyCount, equals(1));
    });

    test('deleteComment removes comment', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      final deleted = await service.deleteComment('video1', comment.id);
      expect(deleted, isTrue);

      final comments = await service.getComments('video1');
      expect(comments, isEmpty);
    });

    test('deleteComment returns false for non-existent', () async {
      final deleted = await service.deleteComment('video1', 'nonexistent');
      expect(deleted, isFalse);
    });

    test('likeComment increases like count', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      await service.likeComment('video1', comment.id, 'user2');
      await service.likeComment('video1', comment.id, 'user3');

      final comments = await service.getComments('video1');
      expect(comments.first.likeCount, equals(2));
    });

    test('unlikeComment decreases like count', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Great video!',
      );

      await service.likeComment('video1', comment.id, 'user2');
      await service.unlikeComment('video1', comment.id, 'user2');

      final comments = await service.getComments('video1');
      expect(comments.first.likeCount, equals(0));
    });

    test('getComments returns all comments', () async {
      await service.postComment('video1', 'user1', 'User 1', 'Comment 1');
      await service.postComment('video1', 'user2', 'User 2', 'Comment 2');
      await service.postComment('video1', 'user3', 'User 3', 'Comment 3');

      final comments = await service.getComments('video1');

      expect(comments, hasLength(3));
    });

    test('getComments topLevelOnly excludes replies', () async {
      final parent = await service.postComment(
        'video1',
        'user1',
        'User 1',
        'Parent comment',
      );

      await service.postComment(
        'video1',
        'user2',
        'User 2',
        'Reply',
        parentCommentId: parent.id,
      );

      final topLevel = await service.getComments('video1', topLevelOnly: true);

      expect(topLevel, hasLength(1));
    });

    test('getComments sorts by creation date (newest first)', () async {
      await service.postComment('video1', 'user1', 'User 1', 'First');
      await Future.delayed(const Duration(milliseconds: 10));
      await service.postComment('video1', 'user2', 'User 2', 'Second');

      final comments = await service.getComments('video1');

      expect(comments.first.text, equals('Second'));
      expect(comments.last.text, equals('First'));
    });

    test('getCommentReplies returns only replies', () async {
      final parent = await service.postComment(
        'video1',
        'user1',
        'User 1',
        'Parent',
      );

      await service.postComment(
        'video1',
        'user2',
        'User 2',
        'Reply 1',
        parentCommentId: parent.id,
      );
      await service.postComment(
        'video1',
        'user3',
        'User 3',
        'Reply 2',
        parentCommentId: parent.id,
      );

      final replies = await service.getCommentReplies('video1', parent.id);

      expect(replies, hasLength(2));
    });

    test('pinComment sets isPinned to true', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Important!',
      );

      await service.pinComment('video1', comment.id);
      final comments = await service.getComments('video1');

      expect(comments.first.isPinned, isTrue);
    });

    test('flagComment sets isFlagged to true', () async {
      final comment = await service.postComment(
        'video1',
        'user1',
        'User One',
        'Inappropriate',
      );

      await service.flagComment('video1', comment.id);
      final comments = await service.getComments('video1');

      expect(comments.first.isFlagged, isTrue);
    });

    test('postReview creates review successfully', () async {
      final review = await service.postReview(
        'video1',
        'user1',
        'User One',
        5,
        'Excellent work!',
        [ReviewCategory.creativity, ReviewCategory.quality],
      );

      expect(review.videoId, equals('video1'));
      expect(review.rating, equals(5));
      expect(review.reviewText, equals('Excellent work!'));
    });

    test('postReview rejects invalid rating', () async {
      expect(
        () => service.postReview(
          'video1',
          'user1',
          'User One',
          6,
          'Invalid',
          [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteReview removes review', () async {
      final review = await service.postReview(
        'video1',
        'user1',
        'User One',
        5,
        'Great!',
        [ReviewCategory.quality],
      );

      final deleted = await service.deleteReview('video1', review.id);
      expect(deleted, isTrue);

      final reviews = await service.getReviews('video1');
      expect(reviews, isEmpty);
    });

    test('markReviewHelpful increases helpful count', () async {
      final review = await service.postReview(
        'video1',
        'user1',
        'User One',
        4,
        'Good',
        [ReviewCategory.quality],
      );

      await service.markReviewHelpful('video1', review.id);
      final reviews = await service.getReviews('video1');

      expect(reviews.first.helpfulCount, equals(1));
    });

    test('getReviews returns all reviews', () async {
      await service.postReview('video1', 'user1', 'User 1', 5, 'Excellent', []);
      await service.postReview('video1', 'user2', 'User 2', 4, 'Good', []);
      await service.postReview('video1', 'user3', 'User 3', 3, 'OK', []);

      final reviews = await service.getReviews('video1');

      expect(reviews, hasLength(3));
    });

    test('getReviews sorts by helpful count', () async {
      final review1 = await service.postReview(
        'video1',
        'user1',
        'User 1',
        5,
        'Excellent',
        [],
      );
      final review2 = await service.postReview(
        'video1',
        'user2',
        'User 2',
        4,
        'Good',
        [],
      );

      await service.markReviewHelpful('video1', review2.id);
      await service.markReviewHelpful('video1', review2.id);

      final reviews = await service.getReviews('video1');

      expect(reviews.first.id, equals(review2.id));
    });

    test('getAverageRating calculates correctly', () async {
      await service.postReview('video1', 'user1', 'User 1', 5, 'Great', []);
      await service.postReview('video1', 'user2', 'User 2', 3, 'OK', []);
      await service.postReview('video1', 'user3', 'User 3', 4, 'Good', []);

      final avg = await service.getAverageRating('video1');

      expect(avg, closeTo(4.0, 0.01));
    });

    test('getRatingDistribution counts ratings correctly', () async {
      await service.postReview('video1', 'user1', 'User 1', 5, 'Great', []);
      await service.postReview('video1', 'user2', 'User 2', 5, 'Excellent', []);
      await service.postReview('video1', 'user3', 'User 3', 4, 'Good', []);

      final dist = await service.getRatingDistribution('video1');

      expect(dist[5], equals(2));
      expect(dist[4], equals(1));
    });

    test('concurrent comments work correctly', () async {
      final futures = List.generate(
        10,
        (i) => service.postComment(
          'video1',
          'user$i',
          'User $i',
          'Comment $i',
        ),
      );

      await Future.wait(futures);
      final comments = await service.getComments('video1');

      expect(comments, hasLength(10));
    });
  });
}
