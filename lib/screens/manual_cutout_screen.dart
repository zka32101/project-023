import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/drawing_stroke.dart';
import '../services/background_removal_service.dart';
import '../widgets/canvas_controls.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/polygon_drawing_mode.dart';
import '../widgets/freehand_drawing_mode.dart';

/// マニュアル切り抜きスクリーン
class ManualCutoutScreen extends ConsumerStatefulWidget {
  /// 処理する画像
  final Uint8List imageBytes;

  /// スクリーンタイトル
  final String title;

  /// 完了時のコールバック（透明PNG）
  final ValueChanged<Uint8List>? onComplete;

  const ManualCutoutScreen({
    Key? key,
    required this.imageBytes,
    this.title = 'マニュアル切り抜き',
    this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<ManualCutoutScreen> createState() =>
      _ManualCutoutScreenState();
}

class _ManualCutoutScreenState extends ConsumerState<ManualCutoutScreen> {
  late DrawingMode currentMode;
  late DrawingHistory history;
  late CanvasController canvasController;
  Image? backgroundImage;

  List<Offset> polygonVertices = [];
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    currentMode = DrawingMode.polygon;
    history = DrawingHistory();
    canvasController = CanvasController();

    // 画像をデコード
    _initializeImage();
  }

  void _initializeImage() {
    _decodeImage(widget.imageBytes).then((image) {
      if (mounted) {
        setState(() {
          backgroundImage = image;
        });
      }
    });
  }

  Future<Image> _decodeImage(Uint8List bytes) async {
    final completer = Completer<Image>();
    final image = Image.memory(
      bytes,
      fit: BoxFit.contain,
    );

    // Image ウィジェットのイメージストリームリスナーを設定
    image.image!.addListener(
      ImageStreamListener(
        (image, synchronousCall) {
          completer.complete(image.image);
        },
        onError: (error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      ),
    );

    return completer.future;
  }

  void _onModeChanged(DrawingMode mode) {
    setState(() {
      currentMode = mode;
      // モード変更時に履歴をクリア
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
        _showClearConfirmation();
        break;
      case 'reset_canvas':
        canvasController.reset();
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('描画をクリアしますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                history.clear();
                polygonVertices.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }

  void _onPolygonComplete(List<Offset> vertices) async {
    setState(() => isProcessing = true);

    try {
      // マスク生成ロジック（Day 5で実装）
      // 今は仮のアラートを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('多角形完了: ${vertices.length}頂点'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _onStrokeAdded(DrawingStroke stroke) {
    history.addStroke(stroke);
    setState(() {});
  }

  void _onStrokeRemoved() {
    history.removeLastStroke();
    setState(() {});
  }

  void _onPolygonVerticesChanged(List<Offset> vertices) {
    setState(() {
      polygonVertices = vertices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        actions: [
          // 完了ボタン
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : _submitCutout,
                icon: const Icon(Icons.check),
                label: const Text('完了'),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // キャンバス
              Expanded(
                child: _buildCanvas(),
              ),

              // ツールバー
              DrawingToolbar(
                currentMode: currentMode,
                onModeChanged: _onModeChanged,
                onAction: _onToolbarAction,
                canUndo: history.canUndo,
                canRedo: history.canRedo,
              ),
            ],
          ),

          // ローディング表示
          if (isProcessing)
            Container(
              color: Colors.black.withAlpha(150),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    if (backgroundImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          // ピンチズーム
          canvasController.zoom(details.scale, details.localFocalPoint);
        }
      },
      onPanUpdate: (details) {
        // パン操作（ピンチズーム中でない場合）
        if (details.pointerCount == 1) {
          canvasController.pan(details.delta);
        }
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
    );
  }

  Widget _buildDrawingMode() {
    switch (currentMode) {
      case DrawingMode.polygon:
        return PolygonDrawingMode(
          backgroundImage: backgroundImage,
          savedVertices: polygonVertices,
          onVerticesChanged: _onPolygonVerticesChanged,
          onPolygonComplete: _onPolygonComplete,
        );

      case DrawingMode.freehand:
        return FreehandDrawingMode(
          backgroundImage: backgroundImage,
          strokes: history.strokes,
          onStrokeAdded: _onStrokeAdded,
          onStrokeRemoved: _onStrokeRemoved,
        );
    }
  }

  void _submitCutout() async {
    // Day 5でマスク生成と透明化を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Day 5で実装予定: マスク生成と透明化'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    canvasController.dispose();
    super.dispose();
  }
}
