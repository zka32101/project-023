import 'package:flutter/material.dart';

/// キャンバスの変換情報（ズーム、パン）
class CanvasTransform {
  /// パンオフセット（ピクセル）
  final Offset offset;

  /// ズームスケール
  final double scale;

  const CanvasTransform({
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  /// 初期状態にリセット
  CanvasTransform reset() {
    return const CanvasTransform();
  }

  /// パン操作
  CanvasTransform pan(Offset delta) {
    return CanvasTransform(
      offset: offset + delta,
      scale: scale,
    );
  }

  /// ズーム操作（中心点指定）
  CanvasTransform zoom(double factor, Offset center) {
    final newScale = (scale * factor).clamp(0.1, 5.0);
    final scaleDiff = newScale - scale;

    // 中心点周りのズーム計算
    final newOffset = offset - (center * scaleDiff / scale);

    return CanvasTransform(
      offset: newOffset,
      scale: newScale,
    );
  }

  /// スクリーン座標をキャンバス座標に変換
  Offset screenToCanvas(Offset screenPoint) {
    return (screenPoint - offset) / scale;
  }

  /// キャンバス座標をスクリーン座標に変換
  Offset canvasToScreen(Offset canvasPoint) {
    return (canvasPoint * scale) + offset;
  }
}

/// キャンバスコントローラー
class CanvasController extends ChangeNotifier {
  CanvasTransform _transform = const CanvasTransform();

  CanvasTransform get transform => _transform;

  /// パン操作
  void pan(Offset delta) {
    _transform = _transform.pan(delta);
    notifyListeners();
  }

  /// ズーム操作
  void zoom(double factor, Offset center) {
    _transform = _transform.zoom(factor, center);
    notifyListeners();
  }

  /// リセット
  void reset() {
    _transform = _transform.reset();
    notifyListeners();
  }

  /// スクリーン座標をキャンバス座標に変換
  Offset screenToCanvas(Offset screenPoint) {
    return _transform.screenToCanvas(screenPoint);
  }

  /// キャンバス座標をスクリーン座標に変換
  Offset canvasToScreen(Offset canvasPoint) {
    return _transform.canvasToScreen(canvasPoint);
  }
}

/// キャンバス背景を描画するカスタムペイント
class CanvasBackgroundPainter extends CustomPainter {
  final CanvasTransform transform;
  final Size canvasSize;

  CanvasBackgroundPainter({
    required this.transform,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // キャンバス背景色
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey[200]!,
    );

    // グリッドラインの描画（オプション、有効化はコメント外す）
    _drawGrid(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridSize = 20.0;
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    // 垂直線
    var x = transform.offset.dx % (gridSize * transform.scale);
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += gridSize * transform.scale;
    }

    // 水平線
    var y = transform.offset.dy % (gridSize * transform.scale);
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += gridSize * transform.scale;
    }
  }

  @override
  bool shouldRepaint(CanvasBackgroundPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.canvasSize != canvasSize;
  }
}
