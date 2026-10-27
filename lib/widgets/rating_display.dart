import 'package:flutter/material.dart';

class RatingDisplay extends StatefulWidget {
  final double rating;
  final bool showHalfStars;
  final int? count;
  final bool showCount;
  final Function(double)? onRatingChanged;
  final bool interactive;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.showHalfStars = false,
    this.count,
    this.showCount = false,
    this.onRatingChanged,
    this.interactive = false,
  }) : super(key: key);

  @override
  State<RatingDisplay> createState() => _RatingDisplayState();
}

class _RatingDisplayState extends State<RatingDisplay> {
  late double selectedRating;

  @override
  void initState() {
    super.initState();
    selectedRating = widget.rating;
  }

  String buildStarString() {
    int fullStars = widget.rating.toInt();
    bool hasHalf = widget.showHalfStars && (widget.rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);

    String stars = '★' * fullStars;
    if (hasHalf) stars += '✩';
    stars += '☆' * emptyStars;
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.interactive) {
      return GestureDetector(
        onTapDown: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localOffset = box.globalToLocal(details.globalPosition);
          final newRating = ((localOffset.dx / (box.size.width / 5)) + 1).clamp(1.0, 5.0);
          setState(() => selectedRating = newRating);
          widget.onRatingChanged?.call(selectedRating);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buildStarString(),
              style: const TextStyle(fontSize: 18),
            ),
            if (widget.showCount && widget.count != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('(${widget.count})'),
              ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          buildStarString(),
          style: const TextStyle(fontSize: 18),
        ),
        if (widget.showCount && widget.count != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('${widget.rating.toStringAsFixed(1)} (${widget.count})'),
          )
        else if (widget.showCount)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(widget.rating.toStringAsFixed(1)),
          ),
      ],
    );
  }
}
