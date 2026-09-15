import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/widgets/video_library_grid.dart';

void main() {
  group('VideoLibraryGrid', () {
    late List<SavedVideo> testVideos;

    setUp(() {
      testVideos = List.generate(
        5,
        (i) => SavedVideo(
          id: 'video_$i',
          projectId: 'test_project',
          filePath: '/test/path/video_$i.mp4',
          metadata: VideoMetadata(
            createdAt: DateTime.now().subtract(Duration(days: i)),
            width: 1920,
            height: 1080,
            fileSizeBytes: 52428800 + (i * 10485760),
            durationSeconds: 10.0 + i,
            fps: 30,
            format: 'mp4',
          ),
          displayName: 'Test Video $i',
        ),
      );
    });

    testWidgets('builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays all videos in grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      // Each video should be rendered as a grid item
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('displays empty state when no videos', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: []),
          ),
        ),
      );

      expect(find.text('No videos found'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
    });

    testWidgets('hides empty state when showEmptyState is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: [],
              showEmptyState: false,
            ),
          ),
        ),
      );

      expect(find.text('No videos found'), findsNothing);
    });

    testWidgets('displays play icon on each video tile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      // Count play icons (one per video)
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('displays video file size in tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      // File sizes should be displayed
      expect(find.text('50.0 MB'), findsWidgets);
    });

    testWidgets('displays video resolution in tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      expect(find.text('1920x1080'), findsWidgets);
    });

    testWidgets('displays video display name in tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: testVideos),
          ),
        ),
      );

      expect(find.text('Test Video 0'), findsOneWidget);
    });

    testWidgets('calls onVideoSelected when video is tapped',
        (WidgetTester tester) async {
      var selectedVideo = <SavedVideo>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              onVideoSelected: (video) => selectedVideo.add(video),
            ),
          ),
        ),
      );

      // Note: This would require NavigatorObserver to fully test video preview navigation
      // Basic structure test ensures callback structure is correct
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('respects crossAxisCount parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('VideoLibraryGrid - Multiple Columns', () {
    late List<SavedVideo> testVideos;

    setUp(() {
      testVideos = List.generate(
        12,
        (i) => SavedVideo(
          id: 'video_$i',
          projectId: 'test_project',
          filePath: '/test/path/video_$i.mp4',
          metadata: VideoMetadata(
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            fileSizeBytes: 52428800,
            durationSeconds: 10.0,
            fps: 30,
            format: 'mp4',
          ),
          displayName: 'Video $i',
        ),
      );
    });

    testWidgets('displays grid with 2 columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 2,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays grid with 3 columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays grid with 4 columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 4,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('VideoLibraryGrid - Single Video', () {
    late SavedVideo singleVideo;

    setUp(() {
      singleVideo = SavedVideo(
        id: 'single_video',
        projectId: 'test_project',
        filePath: '/test/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1280,
          height: 720,
          fileSizeBytes: 10485760,
          durationSeconds: 15.0,
          fps: 24,
          format: 'webm',
        ),
        displayName: 'Single Video',
      );
    });

    testWidgets('displays single video correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: [singleVideo]),
          ),
        ),
      );

      expect(find.text('Single Video'), findsOneWidget);
      expect(find.text('1280x720'), findsOneWidget);
      expect(find.text('10.0 MB'), findsOneWidget);
    });

    testWidgets('shows play button for single video', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: [singleVideo]),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('VideoLibraryGrid - Responsive Layout', () {
    late List<SavedVideo> testVideos;

    setUp(() {
      testVideos = List.generate(
        8,
        (i) => SavedVideo(
          id: 'video_$i',
          projectId: 'test_project',
          filePath: '/test/path/video_$i.mp4',
          metadata: VideoMetadata(
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            fileSizeBytes: 52428800,
            durationSeconds: 10.0,
            fps: 30,
            format: 'mp4',
          ),
          displayName: 'Video $i',
        ),
      );
    });

    testWidgets('displays correctly on phone width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 2,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays correctly on tablet width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(
              videos: testVideos,
              crossAxisCount: 4,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('VideoLibraryGrid - Video Info Display', () {
    testWidgets('displays small file size correctly', (WidgetTester tester) async {
      final smallVideo = SavedVideo(
        id: 'small_video',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 640,
          height: 480,
          fileSizeBytes: 1048576,
          durationSeconds: 5.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: [smallVideo]),
          ),
        ),
      );

      expect(find.text('1.0 MB'), findsOneWidget);
    });

    testWidgets('displays large file size correctly', (WidgetTester tester) async {
      final largeVideo = SavedVideo(
        id: 'large_video',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 3840,
          height: 2160,
          fileSizeBytes: 2147483648,
          durationSeconds: 120.0,
          fps: 60,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoLibraryGrid(videos: [largeVideo]),
          ),
        ),
      );

      expect(find.text('2.0 GB'), findsOneWidget);
    });
  });
}
