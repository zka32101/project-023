/// Service for managing video comments and reviews

import 'package:tsukuani/models/video_comment.dart';

/// Service for handling comments and reviews on videos
class VideoCommentsService {
  static VideoCommentsService? _instance;

  /// Storage for comments by video ID
  final Map<String, List<VideoComment>> _comments = {};

  /// Storage for reviews by video ID
  final Map<String, List<VideoReview>> _reviews = {};

  /// Storage for user comment likes
  final Map<String, Set<String>> _commentLikes = {};

  /// Singleton instance
  static VideoCommentsService get instance {
    _instance ??= VideoCommentsService._();
    return _instance;
  }

  VideoCommentsService._();

  /// Post a comment on a video
  Future<VideoComment> postComment(
    String videoId,
    String userId,
    String userDisplayName,
    String text, {
    String? parentCommentId,
    String? userProfileImageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final comment = VideoComment(
      id: _generateId(),
      videoId: videoId,
      userId: userId,
      userDisplayName: userDisplayName,
      text: text,
      likeCount: 0,
      replyCount: 0,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
      userProfileImageUrl: userProfileImageUrl,
    );

    _comments.putIfAbsent(videoId, () => []);
    _comments[videoId]!.add(comment);

    // Update parent comment reply count
    if (parentCommentId != null) {
      final parentComment = _findComment(videoId, parentCommentId);
      if (parentComment != null) {
        final index = _comments[videoId]!.indexOf(parentComment);
        _comments[videoId]![index] = parentComment.copyWith(
          replyCount: parentComment.replyCount + 1,
        );
      }
    }

    return comment;
  }

  /// Delete a comment
  Future<bool> deleteComment(String videoId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_comments.containsKey(videoId)) return false;

    final comment = _findComment(videoId, commentId);
    if (comment == null) return false;

    _comments[videoId]!.removeWhere((c) => c.id == commentId);
    _commentLikes.remove(commentId);

    return true;
  }

  /// Like a comment
  Future<void> likeComment(String videoId, String commentId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final comment = _findComment(videoId, commentId);
    if (comment == null) return;

    _commentLikes.putIfAbsent(commentId, () => {});
    _commentLikes[commentId]!.add(userId);

    // Update comment like count
    final index = _comments[videoId]!.indexOf(comment);
    _comments[videoId]![index] = comment.copyWith(
      likeCount: comment.likeCount + 1,
    );
  }

  /// Remove like from a comment
  Future<void> unlikeComment(String videoId, String commentId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final comment = _findComment(videoId, commentId);
    if (comment == null) return;

    if (_commentLikes.containsKey(commentId)) {
      _commentLikes[commentId]!.remove(userId);

      // Update comment like count
      final index = _comments[videoId]!.indexOf(comment);
      if (index >= 0) {
        _comments[videoId]![index] = comment.copyWith(
          likeCount: comment.likeCount > 0 ? comment.likeCount - 1 : 0,
        );
      }
    }
  }

  /// Get all comments for a video
  Future<List<VideoComment>> getComments(
    String videoId, {
    bool topLevelOnly = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_comments.containsKey(videoId)) return [];

    var comments = _comments[videoId]!.toList();

    if (topLevelOnly) {
      comments = comments.where((c) => !c.isReply).toList();
    }

    // Sort by creation date (newest first)
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return comments;
  }

  /// Get replies to a comment
  Future<List<VideoComment>> getCommentReplies(String videoId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_comments.containsKey(videoId)) return [];

    return _comments[videoId]!
        .where((c) => c.parentCommentId == commentId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Pin a comment
  Future<void> pinComment(String videoId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final comment = _findComment(videoId, commentId);
    if (comment == null) return;

    final index = _comments[videoId]!.indexOf(comment);
    _comments[videoId]![index] = comment.copyWith(isPinned: true);
  }

  /// Unpin a comment
  Future<void> unpinComment(String videoId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final comment = _findComment(videoId, commentId);
    if (comment == null) return;

    final index = _comments[videoId]!.indexOf(comment);
    _comments[videoId]![index] = comment.copyWith(isPinned: false);
  }

  /// Flag a comment for moderation
  Future<void> flagComment(String videoId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final comment = _findComment(videoId, commentId);
    if (comment == null) return;

    final index = _comments[videoId]!.indexOf(comment);
    _comments[videoId]![index] = comment.copyWith(isFlagged: true);
  }

  /// Post a review for a video
  Future<VideoReview> postReview(
    String videoId,
    String userId,
    String userDisplayName,
    int rating,
    String reviewText,
    List<ReviewCategory> categories,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    final review = VideoReview(
      id: _generateId(),
      videoId: videoId,
      userId: userId,
      userDisplayName: userDisplayName,
      rating: rating,
      reviewText: reviewText,
      categories: categories,
      helpfulCount: 0,
      createdAt: DateTime.now(),
    );

    _reviews.putIfAbsent(videoId, () => []);
    _reviews[videoId]!.add(review);

    return review;
  }

  /// Delete a review
  Future<bool> deleteReview(String videoId, String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_reviews.containsKey(videoId)) return false;

    final initialLength = _reviews[videoId]!.length;
    _reviews[videoId]!.removeWhere((r) => r.id == reviewId);

    return _reviews[videoId]!.length < initialLength;
  }

  /// Mark a review as helpful
  Future<void> markReviewHelpful(String videoId, String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_reviews.containsKey(videoId)) return;

    final review = _reviews[videoId]!.firstWhere(
      (r) => r.id == reviewId,
      orElse: () => null as dynamic,
    ) as VideoReview?;

    if (review != null) {
      final index = _reviews[videoId]!.indexOf(review);
      _reviews[videoId]![index] = review.copyWith(
        helpfulCount: review.helpfulCount + 1,
      );
    }
  }

  /// Get all reviews for a video
  Future<List<VideoReview>> getReviews(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_reviews.containsKey(videoId)) return [];

    var reviews = _reviews[videoId]!.toList();
    reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    return reviews;
  }

  /// Get average rating for a video
  Future<double> getAverageRating(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!_reviews.containsKey(videoId) || _reviews[videoId]!.isEmpty) {
      return 0.0;
    }

    final sum = _reviews[videoId]!.fold<int>(0, (sum, r) => sum + r.rating);
    return sum / _reviews[videoId]!.length;
  }

  /// Get rating distribution
  Future<Map<int, int>> getRatingDistribution(String videoId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    if (!_reviews.containsKey(videoId)) return distribution;

    for (final review in _reviews[videoId]!) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }

    return distribution;
  }

  /// Find a comment by ID
  VideoComment? _findComment(String videoId, String commentId) {
    if (!_comments.containsKey(videoId)) return null;

    try {
      return _comments[videoId]!.firstWhere((c) => c.id == commentId);
    } catch (e) {
      return null;
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Clear all data (for testing)
  void clearData() {
    _comments.clear();
    _reviews.clear();
    _commentLikes.clear();
  }
}
