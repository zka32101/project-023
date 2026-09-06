import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_stroke.dart';
import '../models/custom_character.dart';
import '../services/background_removal_service.dart';
import '../utils/logger.dart';
import '../widgets/canvas_controls.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/polygon_drawing_mode.dart';
import '../widgets/freehand_drawing_mode.dart';

/// マニュアル切り抜きスクリーン
class ManualCutoutScreen extends ConsumerStatefulWidget {
  /// 処理する画像
  final Uint8List imageBytes;

  const ManualCutoutScreen({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  @override
  ConsumerState<ManualCutoutScreen> createState() =>
      _ManualCutoutScreenState();
}

class _ManualCutoutScreenState extends ConsumerState<ManualCutoutScreen> {
  late DrawingMode currentMode;
  late DrawingHistory history;
  late CanvasController canvasController;

  List<Offset> polygonVertices = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    currentMode = DrawingMode.polygon;
    history = DrawingHistory();
    canvasController = CanvasController();
  }

  void _onModeChanged(DrawingMode mode) {
    setState(() {
      currentMode = mode;
      history.clear();
      polygonVertices.clear();
    });
  }

  void _onToolbarAction(String action) {
    switch (action) {
      case 'undo':
        setState(() => history.undo());
        break;
      case 'redo':
        setState(() => history.redo());
        break;
      case 'clear':
        setState(() {
          history.clear();
          polygonVertices.clear();
        });
        break;
      case 'reset_canvas':
        canvasController.reset();
        break;
    }
  }

  Future<void> _processPolygonAndReturn() async {
    if (polygonVertices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('多角形には最低3つ以上の頂点が必要です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // キャンバスサイズを取得（画像サイズに合わせて調整）
      final canvasSize = Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * 0.6, // 画像表示エリアの高さ
      );

      // 多角形マスクを生成
      final maskImage =
          await BackgroundRemovalService.generateMaskFromPolygon(
        polygonVertices,
        canvasSize,
      );

      if (maskImage == null) {
        _showError('マスク生成に失敗しました');
        return;
      }

      // マスクを画像に適用
      final processedImage =
          await BackgroundRemovalService.applyManualMask(
        widget.imageBytes,
        maskImage,
      );

      if (processedImage == null) {
        _showError('マスク適用に失敗しました');
        return;
      }

      // 透明PNG をファイルに保存
      final imagePath =
          await BackgroundRemovalService.saveTransparentPng(
        processedImage,
        'polygon_cutout',
      );

      if (imagePath == null) {
        _showError('ファイル保存に失敗しました');
        return;
      }

      // CustomCharacterを作成して返す
      if (mounted) {
        final character = CustomCharacter(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '手動切り抜きキャラ',
          imagePath: imagePath,
          sourceType: 'manual_cutout',
          removalMethod: 'polygon',
          hasTransparency: true,
          originalFileSize: widget.imageBytes.length,
        );

        Navigator.pop(context, character);
      }
    } catch (e) {
      _showError('処理中にエラーが発生しました: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processFreehandAndReturn() async {
    if (history.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フリーハンドで背景を描いてください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // キャンバスサイズを取得
      final canvasSize = Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * 0.6,
      );

      // フリーハンドマスクを生成
      final maskImage =
          await BackgroundRemovalService.generateMaskFromFreehand(
        history.strokes,
        canvasSize,
      );

      if (maskImage == null) {
        _showError('マスク生成に失敗しました');
        return;
      }

      // マスクを画像に適用
      final processedImage =
          await BackgroundRemovalService.applyManualMask(
        widget.imageBytes,
        maskImage,
      );

      if (processedImage == null) {
        _showError('マスク適用に失敗しました');
        return;
      }

      // 透明PNG をファイルに保存
      final imagePath =
          await BackgroundRemovalService.saveTransparentPng(
        processedImage,
        'freehand_cutout',
      );

      if (imagePath == null) {
        _showError('ファイル保存に失敗しました');
        return;
      }

      // CustomCharacterを作成して返す
      if (mounted) {
        final character = CustomCharacter(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '手動切り抜きキャラ',
          imagePath: imagePath,
          sourceType: 'manual_cutout',
          removalMethod: 'freehand',
          hasTransparency: true,
          originalFileSize: widget.imageBytes.length,
        );

        Navigator.pop(context, character);
      }
    } catch (e) {
      _showError('処理中にエラーが発生しました: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    AppLogger.error('Manual Cutout', message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マニュアル切り抜き'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                if (details.scale != 1.0) {
                  canvasController.zoom(details.scale, details.localFocalPoint);
                }
              },
              onPanUpdate: (details) {
                canvasController.pan(details.delta);
              },
              child: Container(
                color: Colors.grey[300],
                child: Transform.translate(
                  offset: canvasController.transform.offset,
                  child: Transform.scale(
                    scale: canvasController.transform.scale,
                    alignment: Alignment.topLeft,
                    child: _buildDrawingMode(),
                  ),
                ),
              ),
            ),
          ),
          DrawingToolbar(
            currentMode: currentMode,
            onModeChanged: _onModeChanged,
            onAction: _onToolbarAction,
            canUndo: history.canUndo,
            canRedo: history.canRedo,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingMode() {
    final backgroundImage = Image.memory(
      widget.imageBytes,
      fit: BoxFit.contain,
    );

    switch (currentMode) {
      case DrawingMode.polygon:
        return Stack(
          children: [
            PolygonDrawingMode(
              backgroundImage: backgroundImage,
              savedVertices: polygonVertices,
              onVerticesChanged: (vertices) {
                setState(() => polygonVertices = vertices);
              },
              onPolygonComplete: (vertices) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('多角形完了: ${vertices.length}頂点'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              onApplyMask: _processPolygonAndReturn,
            ),
            if (_isProcessing)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );

      case DrawingMode.freehand:
        return Stack(
          children: [
            FreehandDrawingMode(
              backgroundImage: backgroundImage,
              strokes: history.strokes,
              onStrokeAdded: (stroke) {
                history.addStroke(stroke);
                setState(() {});
              },
              onStrokeRemoved: () {
                history.removeLastStroke();
                setState(() {});
              },
              onApplyMask: _processFreehandAndReturn,
            ),
            if (_isProcessing)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );
    }
  }

  @override
  void dispose() {
    canvasController.dispose();
    super.dispose();
  }
}
