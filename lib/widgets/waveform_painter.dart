import 'package:flutter/material.dart';

/// 波形を描画するカスタムペイント
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;

  WaveformPainter({
    required this.amplitudes,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRecording ? Colors.red : Colors.green
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerY = size.height / 2;
    final stepX = size.width / (amplitudes.isEmpty ? 1 : amplitudes.length);

    if (amplitudes.isEmpty) {
      // 波形がない場合は中央線を描画
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        paint..color = Colors.grey.shade700,
      );
      return;
    }

    // 波形を描画
    final path = Path();
    path.moveTo(0, centerY);

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * stepX;
      // 振幅値を画面高さにマッピング（最大値0-1.0）
      final amplitude = (amplitudes[i] * 100).clamp(0.0, 1.0);
      final y = centerY - (centerY * amplitude);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // グリッドラインを描画（複数のセクション）
    final gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 0.5;

    for (int i = 1; i < 4; i++) {
      final y = centerY + (centerY * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 中央線を描画
    final centerPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), centerPaint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.isRecording != isRecording;
  }
}
