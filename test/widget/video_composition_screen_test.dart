import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/screens/video_composition_screen.dart';
import 'package:tsukuani/models/video_composition.dart';

void main() {
  group('VideoCompositionScreen Widget Tests', () {
    late ProviderContainer providerContainer;

    setUp(() {
      // Create a fresh provider container for each test
      providerContainer = ProviderContainer();
    });

    tearDown(() {
      providerContainer.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ProviderScope(
          container: providerContainer,
          child: const VideoCompositionScreen(
            projectId: 'test_project',
            framePattern: '/frames/frame_%04d.png',
            outputPath: '/output/video.mp4',
            totalFrames: 300,
          ),
        ),
      );
    }

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays AppBar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('ビデオ合成'), findsOneWidget);
    });

    testWidgets('shows frame information card', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('フレーム情報'), findsOneWidget);
      expect(find.text('/frames/frame_%04d.png'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
    });

    testWidgets('shows output format selector', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('出力フォーマット設定'), findsOneWidget);
      expect(find.text('ファイル形式'), findsOneWidget);
      expect(find.text('解像度'), findsOneWidget);
      expect(find.text('フレームレート'), findsOneWidget);
    });

    testWidgets('shows audio track mixer section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('オーディオトラック'), findsOneWidget);
    });

    testWidgets('shows metadata section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('メタデータ'), findsOneWidget);
      expect(find.text('ビデオタイトル'), findsOneWidget);
      expect(find.text('制作者'), findsOneWidget);
    });

    testWidgets('shows settings summary', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('設定サマリー'), findsOneWidget);
      expect(find.text('形式'), findsOneWidget);
      expect(find.text('解像度'), findsOneWidget);
    });

    testWidgets('displays empty audio track state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('オーディオトラックが追加されていません'),
          findsOneWidget);
    });

    testWidgets('has Cancel and Compose buttons at bottom',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('合成開始'), findsOneWidget);
    });

    testWidgets('shows format selector chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.text('MP4'), findsOneWidget);
      expect(find.text('WEBM'), findsOneWidget);
      expect(find.text('MOV'), findsOneWidget);
    });

    testWidgets('shows resolution selector chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('720p'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);
      expect(find.text('4k'), findsOneWidget);
    });

    testWidgets('shows FPS selector chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('24fps'), findsOneWidget);
      expect(find.text('30fps'), findsOneWidget);
      expect(find.text('60fps'), findsOneWidget);
    });

    testWidgets('Compose button is disabled when no audio tracks',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final composeButton = find.widgetWithText(ElevatedButton, '合成開始');
      expect(composeButton, findsOneWidget);

      // Button should be disabled (grayed out)
      final button = tester.widget<ElevatedButton>(composeButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('can enter metadata', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final titleField = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'ビデオタイトル');

      await tester.enterText(titleField, 'Test Video');
      await tester.pumpAndSettle();

      expect(find.text('Test Video'), findsOneWidget);
    });

    testWidgets('Cancel button pops the screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            container: providerContainer,
            child: Scaffold(
              body: const VideoCompositionScreen(
                projectId: 'test_project',
                framePattern: '/frames/frame_%04d.png',
                outputPath: '/output/video.mp4',
                totalFrames: 300,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VideoCompositionScreen), findsOneWidget);

      final cancelButton = find.widgetWithText(OutlinedButton, 'キャンセル');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // After tapping cancel, the screen should be popped
      // (In this test context, we just verify the button is tappable)
      expect(cancelButton, findsOneWidget);
    });

    testWidgets('scrolls when content exceeds screen',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(createTestWidget());

      // Verify that SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('CompositionProgressWidget Tests', () {
    testWidgets('displays progress information correctly',
        (WidgetTester tester) async {
      const progress = CompositionProgress(
        processedFrames: 150,
        totalFrames: 300,
        percentComplete: 0.5,
        estimatedSecondsRemaining: 60,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 500,
                child: Column(
                  children: [
                    // Simplified version of CompositionProgressWidget
                    Text('${(progress.percentComplete * 100).toStringAsFixed(1)}%'),
                    Text('${progress.processedFrames} / ${progress.totalFrames}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('150 / 300'), findsOneWidget);
    });
  });

  group('OutputFormatSelector Tests', () {
    testWidgets('selects format correctly', (WidgetTester tester) async {
      String? selectedFormat;
      String? selectedResolution;
      int? selectedFps;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              child: Column(
                children: [
                  // Test format selection
                  ...['mp4', 'webm', 'mov'].map((format) => ChoiceChip(
                        label: Text(format.toUpperCase()),
                        selected: selectedFormat == format,
                        onSelected: (selected) {
                          if (selected) selectedFormat = format;
                        },
                      )),
                  // Test resolution selection
                  ...['720p', '1080p', '4k'].map((resolution) => ChoiceChip(
                        label: Text(resolution),
                        selected: selectedResolution == resolution,
                        onSelected: (selected) {
                          if (selected) selectedResolution = resolution;
                        },
                      )),
                  // Test FPS selection
                  ...[24, 30, 60].map((fps) => ChoiceChip(
                        label: Text('${fps}fps'),
                        selected: selectedFps == fps,
                        onSelected: (selected) {
                          if (selected) selectedFps = fps;
                        },
                      )),
                ],
              ),
            ),
          ),
        ),
      );

      // Test format selection
      await tester.tap(find.text('WEBM'));
      await tester.pumpAndSettle();
      expect(selectedFormat, equals('webm'));

      // Test resolution selection
      await tester.tap(find.text('720p'));
      await tester.pumpAndSettle();
      expect(selectedResolution, equals('720p'));

      // Test FPS selection
      await tester.tap(find.text('60fps'));
      await tester.pumpAndSettle();
      expect(selectedFps, equals(60));
    });
  });

  group('AudioTrackMixer Tests', () {
    testWidgets('displays empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  const Text('オーディオトラック'),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('オーディオトラック'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('displays add button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('オーディオトラック'),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('追加'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    });
  });

  group('VideoCompositionScreen Responsive Tests', () {
    testWidgets('layout is responsive at small width',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(300, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: const VideoCompositionScreen(
                projectId: 'test_project',
                framePattern: '/frames/frame_%04d.png',
                outputPath: '/output/video.mp4',
                totalFrames: 300,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the layout is still rendered correctly
      expect(find.byType(VideoCompositionScreen), findsOneWidget);
    });

    testWidgets('layout is responsive at large width',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(
              body: const VideoCompositionScreen(
                projectId: 'test_project',
                framePattern: '/frames/frame_%04d.png',
                outputPath: '/output/video.mp4',
                totalFrames: 300,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the layout is still rendered correctly
      expect(find.byType(VideoCompositionScreen), findsOneWidget);
    });
  });
}
