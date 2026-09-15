import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/volume_meter.dart';

void main() {
  group('VolumeMeter Widget', () {
    testWidgets('renders with low amplitude', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.2,
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.byType(VolumeMeter), findsOneWidget);
      expect(find.text('レベル: 20%'), findsOneWidget);
      expect(find.text('スタンバイ'), findsOneWidget);
    });

    testWidgets('renders with medium amplitude', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.5,
              isRecording: true,
            ),
          ),
        ),
      );

      expect(find.byType(VolumeMeter), findsOneWidget);
      expect(find.text('レベル: 50%'), findsOneWidget);
      expect(find.text('録音中'), findsOneWidget);
    });

    testWidgets('renders with high amplitude', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.9,
              isRecording: true,
            ),
          ),
        ),
      );

      expect(find.byType(VolumeMeter), findsOneWidget);
      expect(find.text('レベル: 90%'), findsOneWidget);
    });

    testWidgets('displays correct status when not recording', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.3,
              isRecording: false,
            ),
          ),
        ),
      );

      final statusText = find.text('スタンバイ');
      expect(statusText, findsOneWidget);
    });

    testWidgets('displays correct status when recording', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.5,
              isRecording: true,
            ),
          ),
        ),
      );

      final statusText = find.text('録音中');
      expect(statusText, findsOneWidget);
    });

    testWidgets('displays scale labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.4,
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.text('静か'), findsOneWidget);
      expect(find.text('通常'), findsOneWidget);
      expect(find.text('大きい'), findsOneWidget);
    });

    testWidgets('updates when amplitude changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.2,
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.text('レベル: 20%'), findsOneWidget);

      // Rebuild with new amplitude
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.8,
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.text('レベル: 80%'), findsOneWidget);
    });

    testWidgets('updates when recording status changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.5,
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.text('スタンバイ'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolumeMeter(
              amplitude: 0.5,
              isRecording: true,
            ),
          ),
        ),
      );

      expect(find.text('録音中'), findsOneWidget);
    });
  });
}
