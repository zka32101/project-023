import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/waveform_painter.dart';

void main() {
  group('WaveformPainter', () {
    test('creates instance with correct values', () {
      final painter = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: true,
      );

      expect(painter.amplitudes, [0.1, 0.2, 0.3]);
      expect(painter.isRecording, true);
    });

    test('shouldRepaint returns true when amplitudes change', () {
      final painter1 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: true,
      );

      final painter2 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.4],
        isRecording: true,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when recording status changes', () {
      final painter1 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: true,
      );

      final painter2 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: false,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: true,
      );

      final painter2 = WaveformPainter(
        amplitudes: [0.1, 0.2, 0.3],
        isRecording: true,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    testWidgets('renders empty waveform', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitudes: [],
                isRecording: false,
              ),
              size: const Size(300, 150),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders waveform with single sample', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitudes: [0.5],
                isRecording: true,
              ),
              size: const Size(300, 150),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders waveform with multiple samples', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitudes: [0.1, 0.2, 0.3, 0.4, 0.5, 0.4, 0.3, 0.2, 0.1],
                isRecording: true,
              ),
              size: const Size(300, 150),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('updates when recording status changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitudes: [0.2, 0.4, 0.3],
                isRecording: false,
              ),
              size: const Size(300, 150),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: WaveformPainter(
                amplitudes: [0.2, 0.4, 0.3],
                isRecording: true,
              ),
              size: const Size(300, 150),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}
