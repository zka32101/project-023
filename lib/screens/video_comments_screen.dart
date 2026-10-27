import 'package:flutter/material.dart';
import 'package:tsukuani/models/video_comment.dart';
import 'package:tsukuani/services/video_comments_service.dart';

class VideoCommentsScreen extends StatefulWidget {
  final String videoId;
  final bool showRatings;
  final int pageSize;

  const VideoCommentsScreen({
    Key? key,
    required this.videoId,
    this.showRatings = false,
    this.pageSize = 10,
  }) : super(key: key);

  @override
  State<VideoCommentsScreen> createState() => _VideoCommentsScreenState();
}

class _VideoCommentsScreenState extends State<VideoCommentsScreen> with SingleTickerProviderStateMixin {
  late VideoCommentsService commentsService;
  late TabController tabController;

  List<VideoComment> comments = [];
  List<VideoReview> reviews = [];
  TextEditingController commentController = TextEditingController();
  bool isLoading = true;
  double averageRating = 0.0;
  Set<String> likedComments = {};

  @override
  void initState() {
    super.initState();
    commentsService = VideoCommentsService.instance;
    tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  @override
  void dispose() {
    tabController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final loadedComments = await commentsService.getComments(widget.videoId);
    final loadedReviews = await commentsService.getReviews(widget.videoId);
    final avgRating = await commentsService.getAverageRating(widget.videoId);

    setState(() {
      comments = loadedComments;
      reviews = loadedReviews;
      averageRating = avgRating;
      isLoading = false;
    });
  }

  Future<void> postComment(String text) async {
    if (text.isEmpty) return;

    await commentsService.postComment(
      widget.videoId,
      'current_user_id',
      'Current User',
      text,
    );

    commentController.clear();
    await loadData();
  }

  Future<void> toggleLike(VideoComment comment) async {
    if (likedComments.contains(comment.id)) {
      await commentsService.unlikeComment(widget.videoId, comment.id, 'current_user_id');
      setState(() => likedComments.remove(comment.id));
    } else {
      await commentsService.likeComment(widget.videoId, comment.id, 'current_user_id');
      setState(() => likedComments.add(comment.id));
    }
    await loadData();
  }

  String getStarRating(int rating) {
    String stars = '★' * rating;
    stars += '☆' * (5 - rating);
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments & Reviews'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Comments'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.showRatings && averageRating > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Text(
                          getStarRating(averageRating.toInt()),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Average: ${averageRating.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      // Comments Tab
                      comments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet. Be the first!',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          comment.userDisplayName[0].toUpperCase(),
                                        ),
                                      ),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(comment.userDisplayName),
                                          if (comment.isPinned)
                                            const Icon(Icons.push_pin, size: 16),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(comment.text),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => toggleLike(comment),
                                                child: Icon(
                                                  likedComments.contains(comment.id)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 16,
                                                  color: likedComments.contains(comment.id)
                                                      ? Colors.red
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text('Likes: ${comment.likeCount}'),
                                              const SizedBox(width: 16),
                                              Text('Replies: ${comment.replyCount}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      // Reviews Tab
                      reviews.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No reviews yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                final review = reviews[index];
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          review.userDisplayName[0].toUpperCase(),
                                        ),
                                      ),
                                      title: Text(review.userDisplayName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(getStarRating(review.rating)),
                                          const SizedBox(height: 4),
                                          Text(review.reviewText),
                                          if (review.categories.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Wrap(
                                                spacing: 4,
                                                children: review.categories.map((cat) {
                                                  return Chip(
                                                    label: Text(cat.name),
                                                    visualDensity: VisualDensity.compact,
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Text('${review.helpfulCount} helpful'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              onPressed: () => postComment(commentController.text),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
