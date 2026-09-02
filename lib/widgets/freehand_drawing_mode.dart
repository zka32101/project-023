import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/drawing_stroke.dart';

/// フリーハンド描画モード
class FreehandDrawingMode extends StatefulWidget {
  /// 初期画像
  final Image? backgroundImage;

  /// 描画履歴
  final List<DrawingStroke> strokes;

  /// ストローク追加時のコールバック
  final ValueChanged<DrawingStroke>? onStrokeAdded;

  /// ストローク削除時のコールバック
  final VoidCallback? onStrokeRemoved;

  /// ストローク幅
  final double strokeWidth;

  /// ストローク色
  final Color strokeColor;

  const FreehandDrawingMode({
    Key? key,
    this.backgroundImage,
    this.strokes = const [],
    this.onStrokeAdded,
    this.onStrokeRemoved,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
  }) : super(key: key);

  @override
  State<FreehandDrawingMode> createState() => _FreehandDrawingModeState();
}

class _FreehandDrawingModeState extends State<FreehandDrawingMode> {
  late List<DrawingStroke> strokes;
  List<Offset>? currentPoints;

  @override
  void initState() {
    super.initState();
    strokes = List.from(widget.strokes);
  }

  @override
  void didUpdateWidget(FreehandDrawingMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strokes != widget.strokes) {
      strokes = List.from(widget.strokes);
    }
  }

  void _startDrawing(Offset position) {
    setState(() {
      currentPoints = [position];
    });
  }

  void _updateDrawing(Offset position) {
    if (currentPoints != null) {
      setState(() {
        currentPoints!.add(position);
      });
    }
  }

  void _endDrawing() {
    if (currentPoints != null && currentPoints!.length >= 2) {
      final stroke = DrawingStroke(
        points: currentPoints!,
        width: widget.strokeWidth,
        color: widget.strokeColor,
      );

      setState(() {
        strokes.add(stroke);
        currentPoints = null;
      });

      widget.onStrokeAdded?.call(stroke);
    } else {
      setState(() {
        currentPoints = null;
      });
    }
  }

  void _removeLastStroke() {
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
      widget.onStrokeRemoved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _startDrawing(details.localPosition),
      onPanUpdate: (details) => _updateDrawing(details.localPosition),
      onPanEnd: (_) => _endDrawing(),
      child: Stack(
        children: [
          // 背景画像
          if (widget.backgroundImage != null)
            Positioned.fill(
              child: widget.backgroundImage!,
            ),

          // フリーハンド描画
          CustomPaint(
            painter: _FreehandPainter(
              strokes: strokes,
              currentPoints: currentPoints,
              strokeWidth: widget.strokeWidth,
              strokeColor: widget.strokeColor,
            ),
            isComplex: true,
            willChange: true,
          ),

          // ストローク削除ボタン
          if (strokes.isNotEmpty || currentPoints != null)
            Positioned(
              bottom: AppSizes.lg,
              right: AppSizes.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: _removeLastStroke,
                    backgroundColor: Colors.red,
                    mini: true,
                    heroTag: 'remove-stroke',
                    child: const Icon(Icons.backspace),
                  ),
                  const SizedBox(height: AppSizes.md),
                  FloatingActionButton(
                    onPressed: () {
                      // 完了時のアクションはスクリーンで処理
                    },
                    backgroundColor: AppColors.primaryStart,
                    heroTag: 'complete',
                    child: const Icon(Icons.check),
                  ),
                ],
              ),
            ),

          // ストロークカウント表示
          if (strokes.isNotEmpty)
            Positioned(
              top: AppSizes.lg,
              right: AppSizes.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  'ストローク: ${strokes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// フリーハンド描画用カスタムペイント
class _FreehandPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset>? currentPoints;
  final double strokeWidth;
  final Color strokeColor;

  _FreehandPainter({
    required this.strokes,
    this.currentPoints,
    required this.strokeWidth,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 保存済みストロークを描画
    for (final stroke in strokes) {
      if (stroke.points.length >= 2) {
        final path = Path();
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.width
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // 現在描画中のストロークを描画
    if (currentPoints != null && currentPoints!.length >= 2) {
      final path = Path();
      path.moveTo(currentPoints![0].dx, currentPoints![0].dy);

      for (int i = 1; i < currentPoints!.length; i++) {
        path.lineTo(currentPoints![i].dx, currentPoints![i].dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FreehandPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentPoints != currentPoints;
  }
}
