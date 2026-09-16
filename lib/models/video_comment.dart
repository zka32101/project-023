/// Video comment and review models

/// Represents a comment on a video
class VideoComment {
  /// Unique comment ID
  final String id;

  /// Video being commented on
  final String videoId;

  /// User who posted the comment
  final String userId;

  /// User's display name
  final String userDisplayName;

  /// Comment text
  final String text;

  /// Number of likes on this comment
  final int likeCount;

  /// Number of replies to this comment
  final int replyCount;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp (if edited)
  final DateTime? updatedAt;

  /// Parent comment ID (if this is a reply)
  final String? parentCommentId;

  /// User's profile image URL
  final String? userProfileImageUrl;

  /// Whether comment is pinned
  final bool isPinned;

  /// Whether comment is flagged/moderated
  final bool isFlagged;

  VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userDisplayName,
    required this.text,
    required this.likeCount,
    required this.replyCount,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.userProfileImageUrl,
    this.isPinned = false,
    this.isFlagged = false,
  });

  /// Check if comment is edited
  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// Check if this is a reply
  bool get isReply => parentCommentId != null;

  /// Create copy with modified fields
  VideoComment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? userDisplayName,
    String? text,
    int? likeCount,
    int? replyCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    String? userProfileImageUrl,
    bool? isPinned,
    bool? isFlagged,
  }) {
    return VideoComment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      text: text ?? this.text,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      isPinned: isPinned ?? this.isPinned,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'videoId': videoId,
    'userId': userId,
    'userDisplayName': userDisplayName,
    'text': text,
    'likeCount': likeCount,
    'replyCount': replyCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'parentCommentId': parentCommentId,
    'userProfileImageUrl': userProfileImageUrl,
    'isPinned': isPinned,
    'isFlagged': isFlagged,
  };

  /// Create from JSON
  factory VideoComment.fromJson(Map<String, dynamic> json) => VideoComment(
    id: json['id'] as String,
    videoId: json['videoId'] as String,
    userId: json['userId'] as String,
    userDisplayName: json['userDisplayName'] as String,
    text: json['text'] as String,
    likeCount: json['likeCount'] as int,
    replyCount: json['replyCount'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    parentCommentId: json['parentCommentId'] as String?,
    userProfileImageUrl: json['userProfileImageUrl'] as String?,
    isPinned: json['isPinned'] as bool? ?? false,
    isFlagged: json['isFlagged'] as bool? ?? false,
  );

  @override
  String toString() =>
      'VideoComment($userDisplayName, ${text.length} chars, $likeCount likes)';
}

/// Represents a user review/rating for a video
class VideoReview {
  /// Unique review ID
  final String id;

  /// Video being reviewed
  final String videoId;

  /// User who wrote the review
  final String userId;

  /// User's display name
  final String userDisplayName;

  /// Rating (1-5 stars)
  final int rating;

  /// Review text
  final String reviewText;

  /// Review categories
  final List<ReviewCategory> categories;

  /// Number of helpful votes
  final int helpfulCount;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime? updatedAt;

  VideoReview({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userDisplayName,
    required this.rating,
    required this.reviewText,
    required this.categories,
    required this.helpfulCount,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get star rating display
  String getStarRating() => '★' * rating + '☆' * (5 - rating);

  /// Create copy with modified fields
  VideoReview copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? userDisplayName,
    int? rating,
    String? reviewText,
    List<ReviewCategory>? categories,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoReview(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      categories: categories ?? this.categories,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'videoId': videoId,
    'userId': userId,
    'userDisplayName': userDisplayName,
    'rating': rating,
    'reviewText': reviewText,
    'categories': categories.map((c) => c.name).toList(),
    'helpfulCount': helpfulCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Create from JSON
  factory VideoReview.fromJson(Map<String, dynamic> json) => VideoReview(
    id: json['id'] as String,
    videoId: json['videoId'] as String,
    userId: json['userId'] as String,
    userDisplayName: json['userDisplayName'] as String,
    rating: json['rating'] as int,
    reviewText: json['reviewText'] as String,
    categories: (json['categories'] as List<dynamic>)
        .map((c) => ReviewCategory.values.byName(c as String))
        .toList(),
    helpfulCount: json['helpfulCount'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  @override
  String toString() =>
      'VideoReview($userDisplayName, ${getStarRating()}, $helpfulCount helpful)';
}

/// Review categories for categorizing feedback
enum ReviewCategory {
  creativity,
  quality,
  entertaining,
  educational,
  innovative,
}
