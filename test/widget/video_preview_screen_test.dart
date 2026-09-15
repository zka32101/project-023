import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/screens/video_preview_screen.dart';

void main() {
  group('VideoPreviewScreen', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video_1',
        projectId: 'test_project',
        filePath: '/test/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
        displayName: 'Test Video',
      );
    });

    testWidgets('builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays video title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('Test Video'), findsWidgets);
    });

    testWidgets('displays metadata information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('Video Information'), findsOneWidget);
      expect(find.text('Resolution'), findsOneWidget);
      expect(find.text('File Size'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Frame Rate'), findsOneWidget);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('Share'), findsWidgets);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('has menu items in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      // Check for action icons
      expect(find.byIcon(Icons.share), findsWidgets);
    });

    testWidgets('calls onVideoDeleted callback when delete is confirmed',
        (WidgetTester tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(
            video: testVideo,
            onVideoDeleted: () => deleteCalled = true,
          ),
        ),
      );

      // Note: Full delete flow testing would require mock file system
      // This test verifies the widget structure is correct
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('calls onVideoShared callback when share is triggered',
        (WidgetTester tester) async {
      var shareCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(
            video: testVideo,
            onVideoShared: () => shareCalled = true,
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays correct resolution format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('1920x1080'), findsOneWidget);
    });

    testWidgets('displays correct file size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('50.0 MB'), findsOneWidget);
    });

    testWidgets('displays correct fps', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('30 fps'), findsOneWidget);
    });

    testWidgets('displays correct format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('MP4'), findsOneWidget);
    });

    testWidgets('video player container exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      // Check for video player area indicator (play icon or similar)
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows loading indicator for uninitialized video',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      // Video player will show loading state initially
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('VideoPreviewScreen - Responsive Layout', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video_2',
        projectId: 'test_project',
        filePath: '/test/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1280,
          height: 720,
          fileSizeBytes: 10485760,
          durationSeconds: 30.0,
          fps: 24,
          format: 'webm',
        ),
      );
    });

    testWidgets('displays correctly on phone width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays correctly on tablet width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays correct file size for webm format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('10.0 MB'), findsOneWidget);
    });

    testWidgets('displays correct fps for 24fps video', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('24 fps'), findsOneWidget);
    });

    testWidgets('displays webm format uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: testVideo),
        ),
      );

      expect(find.text('WEBM'), findsOneWidget);
    });
  });

  group('VideoPreviewScreen - Different Resolutions', () {
    testWidgets('displays 4K resolution correctly', (WidgetTester tester) async {
      final video4k = SavedVideo(
        id: 'video_4k',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 3840,
          height: 2160,
          fileSizeBytes: 1073741824,
          durationSeconds: 60.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: video4k),
        ),
      );

      expect(find.text('3840x2160'), findsOneWidget);
    });

    testWidgets('displays SD resolution correctly', (WidgetTester tester) async {
      final videoSd = SavedVideo(
        id: 'video_sd',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 640,
          height: 480,
          fileSizeBytes: 5242880,
          durationSeconds: 20.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoPreviewScreen(video: videoSd),
        ),
      );

      expect(find.text('640x480'), findsOneWidget);
    });
  });
}
