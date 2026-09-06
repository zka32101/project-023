import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tsukuani/models/drawing_stroke.dart';
import 'package:tsukuani/services/background_removal_service.dart';

void main() {
  group('BackgroundRemovalService - Manual Cutout Tests', () {
    // テスト用ダミー画像を生成
    Uint8List createDummyImage({int width = 100, int height = 100}) {
      final image = img.Image(width: width, height: height);
      
      // 白い背景
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          image.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
      
      // 中央に黒い四角形（被写体）
      for (int y = 25; y < 75; y++) {
        for (int x = 25; x < 75; x++) {
          image.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
      
      return img.encodePng(image);
    }

    test('Polygon mask generation should not return null', () async {
      final vertices = [
        const Offset(10, 10),
        const Offset(90, 10),
        const Offset(90, 90),
        const Offset(10, 90),
      ];
      
      final mask = await BackgroundRemovalService.generateMaskFromPolygon(
        vertices,
        const Size(100, 100),
      );
      
      expect(mask, isNotNull);
    });

    test('Polygon mask generation should require minimum 3 vertices', () async {
      final vertices = [
        const Offset(10, 10),
        const Offset(90, 10),
      ];
      
      final mask = await BackgroundRemovalService.generateMaskFromPolygon(
        vertices,
        const Size(100, 100),
      );
      
      expect(mask, isNull);
    });

    test('Freehand mask generation should not return null', () async {
      final strokes = [
        DrawingStroke(
          points: [
            const Offset(10, 10),
            const Offset(20, 20),
            const Offset(30, 10),
          ],
          width: 2.0,
          color: Colors.black,
        ),
      ];
      
      final mask = await BackgroundRemovalService.generateMaskFromFreehand(
        strokes,
        const Size(100, 100),
      );
      
      expect(mask, isNotNull);
    });

    test('Freehand mask generation with empty strokes returns null', () async {
      final mask = await BackgroundRemovalService.generateMaskFromFreehand(
        [],
        const Size(100, 100),
      );
      
      expect(mask, isNull);
    });

    test('Apply manual mask should produce transparent PNG', () async {
      final imageBytes = createDummyImage();
      
      // Create a simple mask (black square in center)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 100, 100));
      
      // White background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()..color = Colors.white,
      );
      
      // Black square
      canvas.drawRect(
        const Rect.fromLTWH(25, 25, 50, 50),
        Paint()..color = Colors.black,
      );
      
      final picture = recorder.endRecording();
      final maskImage = await picture.toImage(100, 100);
      
      final resultBytes = await BackgroundRemovalService.applyManualMask(
        imageBytes,
        maskImage,
      );
      
      expect(resultBytes, isNotNull);

      // Verify PNG signature
      expect(resultBytes[0], 137); // PNG signature first byte
      expect(resultBytes[1], 80);  // P
      expect(resultBytes[2], 78);  // N
      expect(resultBytes[3], 71);  // G
    });

    test('Save transparent PNG creates file with correct path', () async {
      final imageBytes = createDummyImage();
      
      final filepath = await BackgroundRemovalService.saveTransparentPng(
        imageBytes,
        'test_image',
      );
      
      expect(filepath, isNotNull);
      expect(filepath!.contains('manual_cutout_characters'), isTrue);
      expect(filepath.endsWith('.png'), isTrue);
      
      // Verify file exists
      final file = File(filepath);
      expect(await file.exists(), isTrue);
      
      // Cleanup
      await file.delete();
    });

    test('Multiple saves create separate files', () async {
      final imageBytes = createDummyImage();
      
      final path1 = await BackgroundRemovalService.saveTransparentPng(
        imageBytes,
        'test_image',
      );
      
      final path2 = await BackgroundRemovalService.saveTransparentPng(
        imageBytes,
        'test_image',
      );
      
      expect(path1, isNotNull);
      expect(path2, isNotNull);
      expect(path1, isNot(path2)); // Different filenames due to timestamp
      
      // Cleanup
      await File(path1!).delete();
      await File(path2!).delete();
    });
  });

  group('Drawing History Tests', () {
    test('DrawingHistory undo/redo operations', () {
      final history = DrawingHistory();
      
      final stroke1 = DrawingStroke(
        points: [const Offset(0, 0), const Offset(10, 10)],
        width: 2.0,
        color: Colors.black,
      );
      
      final stroke2 = DrawingStroke(
        points: [const Offset(20, 20), const Offset(30, 30)],
        width: 2.0,
        color: Colors.black,
      );
      
      // Add strokes
      history.addStroke(stroke1);
      expect(history.strokes.length, 1);
      
      history.addStroke(stroke2);
      expect(history.strokes.length, 2);
      
      // Undo
      history.undo();
      expect(history.strokes.length, 1);
      
      // Redo
      history.redo();
      expect(history.strokes.length, 2);
      
      // Clear
      history.clear();
      expect(history.strokes.length, 0);
    });

    test('DrawingHistory canUndo and canRedo getters', () {
      final history = DrawingHistory();
      
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      
      final stroke = DrawingStroke(
        points: [const Offset(0, 0), const Offset(10, 10)],
        width: 2.0,
        color: Colors.black,
      );
      
      history.addStroke(stroke);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      
      history.undo();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });
  });
}
