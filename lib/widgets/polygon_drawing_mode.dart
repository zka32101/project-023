import 'package:flutter/material.dart';
import '../config/constants.dart';

/// 多角形選択モード
class PolygonDrawingMode extends StatefulWidget {
  /// 初期画像
  final Image? backgroundImage;

  /// キャンバス変換情報
  final Offset canvasOffset;
  final double canvasScale;

  /// 保存済みの多角形頂点
  final List<Offset> savedVertices;

  /// 頂点追加時のコールバック
  final ValueChanged<List<Offset>>? onVerticesChanged;

  /// 完了時のコールバック
  final ValueChanged<List<Offset>>? onPolygonComplete;

  const PolygonDrawingMode({
    Key? key,
    this.backgroundImage,
    this.canvasOffset = Offset.zero,
    this.canvasScale = 1.0,
    this.savedVertices = const [],
    this.onVerticesChanged,
    this.onPolygonComplete,
  }) : super(key: key);

  @override
  State<PolygonDrawingMode> createState() => _PolygonDrawingModeState();
}

class _PolygonDrawingModeState extends State<PolygonDrawingMode> {
  late List<Offset> vertices;
  int? selectedVertexIndex;

  @override
  void initState() {
    super.initState();
    vertices = List.from(widget.savedVertices);
  }

  @override
  void didUpdateWidget(PolygonDrawingMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savedVertices != widget.savedVertices) {
      vertices = List.from(widget.savedVertices);
    }
  }

  void _addVertex(Offset position) {
    setState(() {
      vertices.add(position);
      widget.onVerticesChanged?.call(vertices);
    });
  }

  void _removeVertex(int index) {
    setState(() {
      vertices.removeAt(index);
      selectedVertexIndex = null;
      widget.onVerticesChanged?.call(vertices);
    });
  }

  void _updateVertex(int index, Offset position) {
    setState(() {
      vertices[index] = position;
      widget.onVerticesChanged?.call(vertices);
    });
  }

  void _completePolygon() {
    if (vertices.length >= 3) {
      widget.onPolygonComplete?.call(vertices);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('多角形には最低3つ以上の頂点が必要です'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final pos = details.localPosition;

        // 既存の頂点をタップしたか判定
        bool vertexTapped = false;
        for (int i = 0; i < vertices.length; i++) {
          final distance = (vertices[i] - pos).distance;
          if (distance < 15) {
            // 既存頂点をタップ → 削除
            _removeVertex(i);
            vertexTapped = true;
            break;
          }
        }

        // 新しい頂点を追加
        if (!vertexTapped) {
          _addVertex(pos);
        }
      },
      onPanUpdate: (details) {
        // ドラッグで頂点を移動
        if (selectedVertexIndex != null) {
          final newPos = details.localPosition;
          _updateVertex(selectedVertexIndex!, newPos);
        }
      },
      onPanStart: (details) {
        // ドラッグ開始時に、最も近い頂点を選択
        final pos = details.localPosition;
        double minDistance = double.infinity;
        int? closestIndex;

        for (int i = 0; i < vertices.length; i++) {
          final distance = (vertices[i] - pos).distance;
          if (distance < 20 && distance < minDistance) {
            minDistance = distance;
            closestIndex = i;
          }
        }

        setState(() {
          selectedVertexIndex = closestIndex;
        });
      },
      onPanEnd: (_) {
        setState(() {
          selectedVertexIndex = null;
        });
      },
      child: Stack(
        children: [
          // 背景画像
          if (widget.backgroundImage != null)
            Positioned.fill(
              child: widget.backgroundImage!,
            ),

          // 多角形を描画
          CustomPaint(
            painter: _PolygonPainter(
              vertices: vertices,
              selectedVertexIndex: selectedVertexIndex,
            ),
            isComplex: true,
            willChange: true,
          ),

          // 完了ボタン
          if (vertices.isNotEmpty)
            Positioned(
              bottom: AppSizes.lg,
              right: AppSizes.lg,
              child: FloatingActionButton.extended(
                onPressed: _completePolygon,
                backgroundColor: AppColors.primaryStart,
                icon: const Icon(Icons.check),
                label: const Text('完了'),
              ),
            ),

          // 頂点カウント表示
          if (vertices.isNotEmpty)
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
                  '頂点: ${vertices.length}',
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

/// 多角形描画用カスタムペイント
class _PolygonPainter extends CustomPainter {
  final List<Offset> vertices;
  final int? selectedVertexIndex;

  _PolygonPainter({
    required this.vertices,
    this.selectedVertexIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.isEmpty) return;

    // 多角形の枠線
    if (vertices.length >= 2) {
      final path = Path();
      path.moveTo(vertices[0].dx, vertices[0].dy);

      for (int i = 1; i < vertices.length; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }

      // 閉じた多角形を描画（3個以上の頂点がある場合）
      if (vertices.length >= 3) {
        path.close();

        // 塗りつぶし（半透明）
        canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.primaryStart.withAlpha(50)
            ..style = PaintingStyle.fill,
        );
      }

      // 枠線
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primaryStart
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // 頂点を描画
    for (int i = 0; i < vertices.length; i++) {
      final vertex = vertices[i];
      final isSelected = i == selectedVertexIndex;
      final radius = isSelected ? 10.0 : 8.0;
      final color = isSelected ? Colors.red : AppColors.primaryStart;

      // 頂点の円
      canvas.drawCircle(
        vertex,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // 頂点の枠線
      canvas.drawCircle(
        vertex,
        radius,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // インデックス表示
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          vertex.dx - textPainter.width / 2,
          vertex.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_PolygonPainter oldDelegate) {
    return oldDelegate.vertices != vertices ||
        oldDelegate.selectedVertexIndex != selectedVertexIndex;
  }
}
