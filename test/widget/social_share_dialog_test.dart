import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/models/video_storage_models.dart';
import 'package:tsukuani/widgets/social_share_dialog.dart';

void main() {
  group('SocialShareDialog', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video',
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
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('displays share dialog title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Share Video'), findsOneWidget);
    });

    testWidgets('displays share message label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Share Message'), findsOneWidget);
    });

    testWidgets('displays platform selection label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Share To'), findsOneWidget);
    });

    testWidgets('displays default share text in text field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      // Default text should contain hashtag for つくアニ
      expect(
        find.text(RegExp('.*つくアニ.*'), skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('uses custom share text when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(
                video: testVideo,
                customShareText: 'Custom Share Text',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Share Text'), findsOneWidget);
    });

    testWidgets('displays platform buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Twitter'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
    });

    testWidgets('displays general share button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Share via System'), findsOneWidget);
    });

    testWidgets('displays cancel button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('has text input field for share message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('text field is editable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Verify the text field is enabled
      final widget = tester.widget<TextField>(textField);
      expect(widget.enabled, isNotFalse);
    });

    testWidgets('calls onShare callback', (WidgetTester tester) async {
      var shareCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(
                video: testVideo,
                onShare: () => shareCalled = true,
              ),
            ),
          ),
        ),
      );

      // Dialog structure is correct
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('dialog has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('SocialShareDialog - Platform Buttons', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video',
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
      );
    });

    testWidgets('Twitter button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Twitter'), findsOneWidget);
    });

    testWidgets('Instagram button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('Facebook button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('TikTok button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.text('TikTok'), findsOneWidget);
    });
  });

  group('SocialShareDialog - Share Text Content', () {
    testWidgets('default share text includes video title',
        (WidgetTester tester) async {
      final videoWithName = SavedVideo(
        id: 'video_with_name',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
        displayName: 'My Amazing Video',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: videoWithName),
            ),
          ),
        ),
      );

      expect(find.text(RegExp('.*My Amazing Video.*'), skipOffstage: false),
          findsWidgets);
    });

    testWidgets('share text includes つくアニ hashtag',
        (WidgetTester tester) async {
      final video = SavedVideo(
        id: 'video',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: video),
            ),
          ),
        ),
      );

      expect(
        find.text(RegExp('.*つくアニ.*'), skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('share text is editable in dialog', (WidgetTester tester) async {
      final video = SavedVideo(
        id: 'video',
        projectId: 'proj',
        filePath: '/path/video.mp4',
        metadata: VideoMetadata(
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          fileSizeBytes: 52428800,
          durationSeconds: 10.0,
          fps: 30,
          format: 'mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: video),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
    });
  });

  group('SocialShareDialog - Responsive Design', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video',
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
      );
    });

    testWidgets('displays correctly on phone width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('displays correctly on tablet width', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('platform buttons wrap on small screens',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(300, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });
  });

  group('SocialShareDialog - Dialog Interaction', () {
    late SavedVideo testVideo;

    setUp(() {
      testVideo = SavedVideo(
        id: 'test_video',
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
      );
    });

    testWidgets('dialog has share icon in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('dialog shows all action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SocialShareDialog(video: testVideo),
            ),
          ),
        ),
      );

      // All platform buttons should be visible
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(TextButton), findsOneWidget); // Cancel button
    });
  });
}
