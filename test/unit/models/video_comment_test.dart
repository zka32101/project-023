import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_comment.dart';

void main() {
  group('VideoComment', () {
    test('isEdited returns true when updated', () {
      final now = DateTime.now();
      final comment = VideoComment(
        id: 'comment1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        text: 'Great video!',
        likeCount: 5,
        replyCount: 0,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      expect(comment.isEdited, isTrue);
    });

    test('isEdited returns false when not updated', () {
      final now = DateTime.now();
      final comment = VideoComment(
        id: 'comment1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        text: 'Great video!',
        likeCount: 5,
        replyCount: 0,
        createdAt: now,
      );

      expect(comment.isEdited, isFalse);
    });

    test('isReply returns true for reply comment', () {
      final comment = VideoComment(
        id: 'comment2',
        videoId: 'vid1',
        userId: 'user2',
        userDisplayName: 'User2',
        text: 'Thanks!',
        likeCount: 0,
        replyCount: 0,
        createdAt: DateTime.now(),
        parentCommentId: 'comment1',
      );

      expect(comment.isReply, isTrue);
    });

    test('isReply returns false for top-level comment', () {
      final comment = VideoComment(
        id: 'comment1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        text: 'Great video!',
        likeCount: 5,
        replyCount: 1,
        createdAt: DateTime.now(),
      );

      expect(comment.isReply, isFalse);
    });

    test('copyWith creates new instance with modified fields', () {
      final original = VideoComment(
        id: 'comment1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        text: 'Great video!',
        likeCount: 5,
        replyCount: 2,
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        likeCount: 10,
        isPinned: true,
      );

      expect(modified.likeCount, equals(10));
      expect(modified.isPinned, isTrue);
      expect(modified.id, equals(original.id));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = VideoComment(
        id: 'comment1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User1',
        text: 'Great video!',
        likeCount: 10,
        replyCount: 3,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
        parentCommentId: null,
        isPinned: true,
      );

      final json = original.toJson();
      final restored = VideoComment.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      expect(restored.likeCount, equals(original.likeCount));
      expect(restored.isPinned, isTrue);
    });
  });

  group('VideoReview', () {
    test('getStarRating returns correct format', () {
      final review = VideoReview(
        id: 'review1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        rating: 4,
        reviewText: 'Very good!',
        categories: [ReviewCategory.creativity, ReviewCategory.quality],
        helpfulCount: 5,
        createdAt: DateTime.now(),
      );

      expect(review.getStarRating(), equals('★★★★☆'));
    });

    test('getStarRating for 5 stars', () {
      final review = VideoReview(
        id: 'review1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        rating: 5,
        reviewText: 'Perfect!',
        categories: [ReviewCategory.creativity],
        helpfulCount: 10,
        createdAt: DateTime.now(),
      );

      expect(review.getStarRating(), equals('★★★★★'));
    });

    test('getStarRating for 1 star', () {
      final review = VideoReview(
        id: 'review1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        rating: 1,
        reviewText: 'Not good',
        categories: [ReviewCategory.quality],
        helpfulCount: 0,
        createdAt: DateTime.now(),
      );

      expect(review.getStarRating(), equals('★☆☆☆☆'));
    });

    test('copyWith creates new instance with modified fields', () {
      final original = VideoReview(
        id: 'review1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User',
        rating: 4,
        reviewText: 'Good',
        categories: [ReviewCategory.quality],
        helpfulCount: 5,
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        rating: 5,
        helpfulCount: 10,
      );

      expect(modified.rating, equals(5));
      expect(modified.helpfulCount, equals(10));
      expect(modified.id, equals(original.id));
    });

    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final original = VideoReview(
        id: 'review1',
        videoId: 'vid1',
        userId: 'user1',
        userDisplayName: 'User1',
        rating: 5,
        reviewText: 'Excellent work!',
        categories: [ReviewCategory.creativity, ReviewCategory.quality],
        helpfulCount: 15,
        createdAt: now,
        updatedAt: now.add(const Duration(days: 1)),
      );

      final json = original.toJson();
      final restored = VideoReview.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.rating, equals(original.rating));
      expect(restored.categories, hasLength(2));
      expect(restored.helpfulCount, equals(15));
    });
  });

  group('ReviewCategory Enum', () {
    test('all review categories are defined', () {
      expect(ReviewCategory.values, hasLength(5));
      expect(ReviewCategory.values, contains(ReviewCategory.creativity));
      expect(ReviewCategory.values, contains(ReviewCategory.quality));
      expect(ReviewCategory.values, contains(ReviewCategory.entertaining));
      expect(ReviewCategory.values, contains(ReviewCategory.educational));
      expect(ReviewCategory.values, contains(ReviewCategory.innovative));
    });
  });
}
