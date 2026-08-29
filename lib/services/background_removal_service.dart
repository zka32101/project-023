import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class BackgroundRemovalService {
  /// L1: 白背景を自動削除して透明PNG を返す
  /// [imageBytes] - 入力画像バイト
  /// [threshold] - 白と判定する色差の閾値（0-255）
  /// [tolerance] - 色差の許容値
  static Future<Uint8List?> removeWhiteBackground(
    Uint8List imageBytes, {
    int threshold = 200,
    int tolerance = 30,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        // Failed to decode image
        return null;
      }

      // RGBA に変換（アルファチャンネル追加）
      final resultImage = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4,
      );

      // ピクセルごとに処理
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixelRgba(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // 白判定：R, G, B が全て threshold 以上かつ色差が tolerance 以内
          final max = [r, g, b].reduce((a, b) => a > b ? a : b);
          final min = [r, g, b].reduce((a, b) => a < b ? a : b);
          final isWhite = max >= threshold && (max - min) <= tolerance;

          if (isWhite) {
            // 白背景 → 透明
            resultImage.setPixelRgba(x, y, 0, 0, 0, 0);
          } else {
            // 通常のピクセル（アルファ=255）
            resultImage.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }

      final pngBytes = img.encodePng(resultImage);
      return pngBytes;
    } catch (e) {
      // Background removal error
      return null;
    }
  }

  /// L2: マニュアル切り抜き用マスク適用
  /// [imageBytes] - 入力画像バイト
  /// [maskImage] - マスク画像（白=保持, 黒=削除）
  static Future<Uint8List?> applyManualMask(
    Uint8List imageBytes,
    ui.Image maskImage,
  ) async {
    try {
      final sourceImage = img.decodeImage(imageBytes);
      if (sourceImage == null) {
        // Failed to decode source image
        return null;
      }

      // マスク画像をバイト変換
      final maskByteData =
          await maskImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (maskByteData == null) {
        // Failed to get mask byte data
        return null;
      }

      final maskBytes = maskByteData.buffer.asUint8List();
      final resultImage = img.Image(
        width: sourceImage.width,
        height: sourceImage.height,
        numChannels: 4,
      );

      // マスク適用
      for (int y = 0; y < sourceImage.height; y++) {
        for (int x = 0; x < sourceImage.width; x++) {
          final pixel = sourceImage.getPixelRgba(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // マスクのアルファ値を使用
          final maskIndex = (y * maskImage.width + x) * 4 + 3;
          final maskAlpha = maskBytes[maskIndex];

          resultImage.setPixelRgba(x, y, r, g, b, maskAlpha);
        }
      }

      final pngBytes = img.encodePng(resultImage);
      return pngBytes;
    } catch (e) {
      // Manual mask application error
      return null;
    }
  }

  /// ビデオフレームサイズに最適化
  static img.Image resizeForOptimization(
    img.Image image, {
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) {
    if (image.width > maxWidth || image.height > maxHeight) {
      final aspectRatio = image.width / image.height;
      int newWidth = maxWidth;
      int newHeight = (maxWidth / aspectRatio).toInt();

      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).toInt();
      }

      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }
    return image;
  }
}
