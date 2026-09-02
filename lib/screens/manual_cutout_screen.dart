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
        return PolygonDrawingMode(
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
        );

      case DrawingMode.freehand:
        return FreehandDrawingMode(
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
        );
    }
  }

  @override
  void dispose() {
    canvasController.dispose();
    super.dispose();
  }
}
