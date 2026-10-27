import 'package:flutter/material.dart';
import 'package:tsukuani/models/video_comment.dart';

class CommentCard extends StatefulWidget {
  final VideoComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onExpand;

  const CommentCard({
    Key? key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.onExpand,
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        widget.comment.userDisplayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comment.userDisplayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'just now',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.comment.isPinned)
                  const Icon(Icons.push_pin, size: 16, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.comment.text),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => isLiked = !isLiked);
                    widget.onLike?.call();
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text('Likes: ${widget.comment.likeCount}'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                if (widget.comment.replyCount > 0)
                  GestureDetector(
                    onTap: widget.onExpand,
                    child: Row(
                      children: [
                        const Icon(Icons.comment, size: 16),
                        const SizedBox(width: 4),
                        Text('Replies: ${widget.comment.replyCount}'),
                      ],
                    ),
                  ),
                if (widget.comment.replyCount == 0)
                  GestureDetector(
                    onTap: widget.onReply,
                    child: const Row(
                      children: [
                        Icon(Icons.reply, size: 16),
                        SizedBox(width: 4),
                        Text('Reply'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
