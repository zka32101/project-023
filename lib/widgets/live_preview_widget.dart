import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class LivePreviewWidget extends StatefulWidget {
  final List<String> framePaths;
  final int fps;
  final double size;

  const LivePreviewWidget({
    Key? key,
    required this.framePaths,
    required this.fps,
    this.size = 120,
  }) : super(key: key);

  @override
  State<LivePreviewWidget> createState() => _LivePreviewWidgetState();
}

class _LivePreviewWidgetState extends State<LivePreviewWidget> {
  late Timer _timer;
  int _currentFrameIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  void _startLoop() {
    if (widget.framePaths.length < 3) return;

    final frameDuration = Duration(milliseconds: (1000 / widget.fps).toInt());

    _timer = Timer.periodic(frameDuration, (_) {
      if (mounted) {
        setState(() {
          _currentFrameIndex =
              (_currentFrameIndex + 1) % widget.framePaths.length;
        });
      }
    });
  }

  @override
  void didUpdateWidget(LivePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.framePaths.length != widget.framePaths.length ||
        oldWidget.fps != widget.fps) {
      _timer.cancel();
      _currentFrameIndex = 0;
      _startLoop();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.framePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(100),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Current frame
            Image.file(
              File(widget.framePaths[_currentFrameIndex]),
              fit: BoxFit.cover,
            ),

            // Pulse animation
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.amber.withAlpha(150),
                  width: 2,
                ),
              ),
            ),

            // Frame counter
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${_currentFrameIndex + 1}/${widget.framePaths.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
