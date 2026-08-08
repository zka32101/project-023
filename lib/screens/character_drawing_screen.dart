import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';
import '../models/custom_character.dart';
import '../providers/custom_character_provider.dart';
import '../utils/logger.dart';

// Lets the user draw a custom character with a finger, then saves it as a
// PNG so it can be placed as an AR overlay just like the catalog characters.
class CharacterDrawingScreen extends ConsumerStatefulWidget {
  const CharacterDrawingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CharacterDrawingScreen> createState() =>
      _CharacterDrawingScreenState();
}

class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  _DrawStroke({required this.points, required this.color, required this.width});
}

class _CharacterDrawingScreenState
    extends ConsumerState<CharacterDrawingScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_DrawStroke> _strokes = [];
  Color _activeColor = Colors.black;
  double _activeWidth = 6;
  bool _isSaving = false;

  static const _palette = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _strokes.add(_DrawStroke(
        points: [details.localPosition],
        color: _activeColor,
        width: _activeWidth,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('何か描いてから保存してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return;
      final bytes = pngData.buffer.asUint8List();

      final docsDir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${docsDir.path}/custom_characters');
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '${customDir.path}/character_$id.png';
      await File(path).writeAsBytes(bytes);

      final character = CustomCharacter(id: id, name: 'マイキャラ', imagePath: path);
      await ref.read(customCharacterProvider.notifier).addCharacter(character);

      if (mounted) {
        Navigator.pop(context, character);
      }
    } catch (e) {
      AppLogger.error('Character drawing save error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('マイキャラをかこう'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '元に戻す',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
            tooltip: 'クリア',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: CustomPaint(
                    painter: _DrawingPainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _palette.map((color) {
                final isSelected = _activeColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _activeColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 36 : 28,
                    height: isSelected ? 36 : 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryStart
                            : Colors.grey.shade400,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2.0, 6.0, 14.0].map((w) {
                final isSelected = _activeWidth == w;
                return GestureDetector(
                  onTap: () => setState(() => _activeWidth = w),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryStart.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: w * 2,
                      height: w * 2,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving ? '保存中...' : 'キャラクターにする',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawStroke> strokes;

  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
