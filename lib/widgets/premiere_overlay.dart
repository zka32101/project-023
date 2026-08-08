import 'package:flutter/material.dart';

class PremiereOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const PremiereOverlay({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PremiereOverlay> createState() => _PremiereOverlayState();
}

class _PremiereOverlayState extends State<PremiereOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _startPremiereSequence();
  }

  void _startPremiereSequence() async {
    // Countdown
    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _countdown = i - 1);
      }
    }

    // Start confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Film frame border
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.amber,
              width: 8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(200),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Film strip left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (i) => Container(
                        width: 16,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Film strip right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (i) => Container(
                        width: 16,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Countdown or confetti
              if (_countdown > 0)
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: AlwaysStoppedAnimation(_countdown == 3 ? 0.5 : 1.0),
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Text(
                      _countdown.toString(),
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 10,
                            color: Colors.black.withAlpha(200),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Confetti particles
                ..._buildConfetti(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConfetti() {
    return List.generate(
      20,
      (index) {
        final offset = Tween<Offset>(
          begin: const Offset(0.5, 0.3),
          end: Offset(
            0.2 + (index % 3) * 0.3,
            1.2,
          ),
        ).animate(
          CurvedAnimation(
            parent: _confettiController,
            curve: Curves.easeIn,
          ),
        );

        return AnimatedBuilder(
          animation: offset,
          builder: (context, child) {
            return Positioned(
              left: offset.value.dx * MediaQuery.of(context).size.width,
              top: offset.value.dy * MediaQuery.of(context).size.height,
              child: Transform.rotate(
                angle: index * 0.5,
                child: Opacity(
                  opacity: (1 - _confettiController.value).clamp(0.0, 1.0),
                  child: Icon(
                    [Icons.celebration, Icons.star, Icons.favorite]
                        [index % 3],
                    color: [Colors.amber, Colors.red, Colors.lightBlue][
                        index % 3],
                    size: 20,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
