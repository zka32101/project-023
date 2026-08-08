import 'package:flutter/material.dart';

enum LottieAnimationType {
  shootBounce,
  completeCelebration,
  characterUnlock,
  loading,
  error,
}

class LottieAnimationWidget extends StatelessWidget {
  final LottieAnimationType type;
  final bool repeat;
  final bool reverse;
  final Duration duration;

  const LottieAnimationWidget({
    Key? key,
    required this.type,
    this.repeat = true,
    this.reverse = false,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getLottieIcon(type),
          const SizedBox(height: 8),
          Text(
            _getLabel(type),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Icon _getLottieIcon(LottieAnimationType type) {
    switch (type) {
      case LottieAnimationType.shootBounce:
        return const Icon(Icons.circle, size: 60, color: Colors.red);
      case LottieAnimationType.completeCelebration:
        return const Icon(Icons.celebration, size: 60, color: Colors.green);
      case LottieAnimationType.characterUnlock:
        return const Icon(Icons.star, size: 60, color: Colors.orange);
      case LottieAnimationType.loading:
        return const Icon(Icons.hourglass_empty,
            size: 60, color: Colors.blue);
      case LottieAnimationType.error:
        return const Icon(Icons.error, size: 60, color: Colors.red);
    }
  }

  String _getLabel(LottieAnimationType type) {
    switch (type) {
      case LottieAnimationType.shootBounce:
        return 'Shoot Animation';
      case LottieAnimationType.completeCelebration:
        return 'Complete!';
      case LottieAnimationType.characterUnlock:
        return 'Character Unlocked!';
      case LottieAnimationType.loading:
        return 'Loading...';
      case LottieAnimationType.error:
        return 'Error';
    }
  }
}

class FullScreenLottieOverlay extends StatefulWidget {
  final LottieAnimationType type;
  final Duration duration;
  final VoidCallback? onComplete;

  const FullScreenLottieOverlay({
    Key? key,
    required this.type,
    this.duration = const Duration(seconds: 2),
    this.onComplete,
  }) : super(key: key);

  @override
  State<FullScreenLottieOverlay> createState() =>
      _FullScreenLottieOverlayState();
}

class _FullScreenLottieOverlayState extends State<FullScreenLottieOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: LottieAnimationWidget(type: widget.type, repeat: false),
      ),
    );
  }
}
