import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../config/constants.dart';
import '../models/custom_character.dart';
import '../models/drawing_stroke.dart';
import '../services/background_removal_service.dart';
import '../providers/custom_character_provider.dart';
import '../utils/logger.dart';

class ManualCutoutScreen extends ConsumerStatefulWidget {
  final Uint8List imageBytes;

  const ManualCutoutScreen({Key? key, required this.imageBytes})
      : super(key: key);

  @override
  ConsumerState<ManualCutoutScreen> createState() => _ManualCutoutScreenState();
}

class _ManualCutoutScreenState extends ConsumerState<ManualCutoutScreen> {
  late DrawingHistory _history;
  String _mode = 'polygon'; // 'polygon' or 'freehand'
  ui.Image? _image;
  bool _isProcessing = false;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _history = DrawingHistory();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final image = await _decodeImage(widget.imageBytes);
      setState(() => _image = image);
    } catch (e) {
      AppLogger.error('Load image in manual cutout', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像読み込みエラー: $e')),
        );
      }
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _addStroke(List<Offset> points, StrokeType type) {
    setState(() {
      _history.addStroke(DrawingStroke(
        points: points,
        type: type,
      ));
    });
  }

  void _undo() {
    if (_history.undo()) {
      setState(() {});
    }
  }

  void _redo() {
    if (_history.redo()) {
      setState(() {});
    }
  }

  void _clear() {
    setState(() => _history.clear());
  }

  Future<void> _removeBackground() async {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('何か描いてから実行してください')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // マスク画像生成
      final maskImage = await _generateMask();
      if (maskImage == null) throw Exception('Failed to generate mask');

      // 透明化処理
      final resultBytes = await BackgroundRemovalService.applyManualMask(
        widget.imageBytes,
        maskImage,
      );

      if (resultBytes == null) throw Exception('Failed to apply mask');

      // 保存＆キャラクター登録
      final docsDir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${docsDir.path}/custom_characters');
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '${customDir.path}/character_$id.png';
      await File(path).writeAsBytes(resultBytes);

      final character = CustomCharacter(
        id: id,
        name: 'カットアウトキャラ',
        imagePath: path,
        sourceType: 'photo',
        removalMethod: 'manual',
        hasTransparency: true,
        originalFileSize: widget.imageBytes.length,
      );

      await ref.read(customCharacterProvider.notifier).addCharacter(character);

      if (mounted) {
        Navigator.pop(context, character);
      }
    } catch (e) {
      AppLogger.error('Remove background in manual cutout', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  List<Offset> _currentPolygon = [];
  List<Offset> _currentFreehand = [];

  void _onCanvasTap(TapDownDetails details) {
    if (_mode != 'polygon') return;

    final point = details.localPosition;

    // 最後の点に近ければ完了
    if (_currentPolygon.isNotEmpty &&
        (_currentPolygon.last - point).distance < 20) {
      if (_currentPolygon.length >= 3) {
        _addStroke(_currentPolygon, StrokeType.polygon);
        setState(() => _currentPolygon = []);
      }
      return;
    }

    setState(() => _currentPolygon.add(point));
  }

  void _onDrawStart(DragStartDetails details) {
    if (_mode != 'freehand') return;
    setState(() => _currentFreehand = [details.localPosition]);
  }

  void _onDrawUpdate(DragUpdateDetails details) {
    if (_mode != 'freehand') return;
    setState(() => _currentFreehand.add(details.localPosition));
  }

  void _onDrawEnd(DragEndDetails details) {
    if (_mode != 'freehand' || _currentFreehand.isEmpty) return;
    _addStroke(_currentFreehand, StrokeType.freehand);
    setState(() => _currentFreehand = []);
  }

  Future<ui.Image?> _generateMask() async {
    if (_image == null) return null;

    // キャンバスサイズ
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_image!.width.toDouble(), _image!.height.toDouble());

    // 背景を黒で塗る（マスク初期値）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // ストロークを白で描画（保持領域）
    final paint = Paint()..color = Colors.white;
    for (final stroke in _history.currentStrokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.type == StrokeType.polygon) {
        // 多角形を描画
        canvas.drawPath(
          _createPath(stroke.points, close: true),
          paint,
        );
      } else if (stroke.type == StrokeType.freehand) {
        // フリーハンドを描画
        canvas.drawPath(
          _createPath(stroke.points),
          paint..strokeWidth = stroke.width,
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(_image!.width, _image!.height);
  }

  Path _createPath(List<Offset> points, {bool close = false}) {
    if (points.isEmpty) return Path();

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (close && points.length > 2) {
      path.close();
    }

    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('マニュアルで背景を削除'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // キャンバス
          Expanded(
            child: _image == null
                ? const Center(child: CircularProgressIndicator())
                : MouseRegion(
                    cursor: _mode == 'polygon'
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTapDown: _mode == 'polygon' ? _onCanvasTap : null,
                      onPanStart: _mode == 'freehand' ? _onDrawStart : null,
                      onPanUpdate: (details) {
                        if (_mode == 'freehand') {
                          _onDrawUpdate(details);
                        } else {
                          setState(() => _panOffset += details.delta);
                        }
                      },
                      onPanEnd: _mode == 'freehand' ? _onDrawEnd : null,
                      child: CustomPaint(
                        painter: _ManualCutoutPainter(
                          image: _image!,
                          history: _history,
                          mode: _mode,
                          zoomLevel: _zoomLevel,
                          panOffset: _panOffset,
                          currentPolygon: _currentPolygon,
                          currentFreehand: _currentFreehand,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
          ),

          // ツールバー
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // モード選択
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'polygon',
                            label: Text('多角形'),
                            icon: Icon(Icons.edit),
                          ),
                          ButtonSegment(
                            value: 'freehand',
                            label: Text('フリーハンド'),
                            icon: Icon(Icons.brush),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (value) {
                          setState(() => _mode = value.first);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _history.canUndo ? _undo : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('アンドゥ'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _history.canRedo ? _redo : null,
                        icon: const Icon(Icons.redo),
                        label: const Text('リドゥ'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _history.isEmpty ? null : _clear,
                        icon: const Icon(Icons.delete),
                        label: const Text('クリア'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // 実行ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _removeBackground,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isProcessing ? '処理中...' : 'キャラクターにする',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCutoutPainter extends CustomPainter {
  final ui.Image image;
  final DrawingHistory history;
  final String mode;
  final double zoomLevel;
  final Offset panOffset;
  final List<Offset> currentPolygon;
  final List<Offset> currentFreehand;

  _ManualCutoutPainter({
    required this.image,
    required this.history,
    required this.mode,
    required this.zoomLevel,
    required this.panOffset,
    required this.currentPolygon,
    required this.currentFreehand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景描画
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade800,
    );

    // 画像描画（ズーム & パン適用）
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    canvas.drawImage(image, Offset.zero, Paint());

    // 描画ストロークを重ねる
    _drawStrokes(canvas);

    // 進行中のストロークを描画
    if (currentPolygon.isNotEmpty && mode == 'polygon') {
      const pointRadius = 6.0;
      const pointColor = Colors.cyan;
      final paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentPolygon.length - 1; i++) {
        canvas.drawLine(currentPolygon[i], currentPolygon[i + 1], paint);
      }

      for (final point in currentPolygon) {
        canvas.drawCircle(point, pointRadius, Paint()..color = pointColor);
      }
    } else if (currentFreehand.isNotEmpty && mode == 'freehand') {
      final paint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentFreehand.length - 1; i++) {
        canvas.drawLine(currentFreehand[i], currentFreehand[i + 1], paint);
      }
    }

    canvas.restore();

    // ズームレベル表示
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Zoom: ${(zoomLevel * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }

  void _drawStrokes(Canvas canvas) {
    const pointRadius = 6.0;
    const pointColor = Colors.cyan;

    for (final stroke in history.currentStrokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.type == StrokeType.polygon) {
        // 多角形の辺を描画
        final paint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        if (stroke.points.length > 1) {
          for (int i = 0; i < stroke.points.length - 1; i++) {
            canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
          }
          // 最後の点と最初の点を繋ぐ
          if (stroke.points.length > 2) {
            canvas.drawLine(
              stroke.points.last,
              stroke.points.first,
              paint,
            );
          }
        }

        // 頂点を描画
        for (final point in stroke.points) {
          canvas.drawCircle(point, pointRadius, Paint()..color = pointColor);
        }
      } else if (stroke.type == StrokeType.freehand) {
        // フリーハンドを描画
        final paint = Paint()
          ..color = Colors.green
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ManualCutoutPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.history != history ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.currentPolygon != currentPolygon ||
        oldDelegate.currentFreehand != currentFreehand;
  }
}
