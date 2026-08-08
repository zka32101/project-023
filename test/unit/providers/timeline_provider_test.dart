import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuani/providers/timeline_provider.dart';
import 'package:tsukuani/models/frame.dart';

void main() {
  group('TimelineStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(timelineStateProvider);
      expect(state.frames, isEmpty);
      expect(state.selectedFrameIndex, isNull);
      expect(state.isPlaying, isFalse);
    });

    test('should calculate duration correctly', () {
      final notifier = container.read(timelineStateProvider.notifier);

      // Create 10 frames
      for (int i = 0; i < 10; i++) {
        final frame = Frame(
          frameId: 'frame_$i',
          capturedAt: DateTime.now(),
          imageUrl: '/path/to/frame_$i.jpg',
          characters: [],
          order: i,
        );
        notifier.addFrame(frame);
      }

      final state = container.read(timelineStateProvider);
      final duration = state.calculateDuration(10); // 10 fps
      expect(duration, equals(1.0)); // 10 frames / 10 fps = 1 second
    });

    test('should add frame', () {
      final notifier = container.read(timelineStateProvider.notifier);
      final frame = Frame(
        frameId: 'frame_0',
        capturedAt: DateTime.now(),
        imageUrl: '/path/to/frame_0.jpg',
        characters: [],
        order: 0,
      );

      notifier.addFrame(frame);

      final state = container.read(timelineStateProvider);
      expect(state.frames.length, equals(1));
      expect(state.frames.first.frameId, equals('frame_0'));
    });

    test('should remove frame', () {
      final notifier = container.read(timelineStateProvider.notifier);

      // Add 3 frames
      for (int i = 0; i < 3; i++) {
        final frame = Frame(
          frameId: 'frame_$i',
          capturedAt: DateTime.now(),
          imageUrl: '/path/to/frame_$i.jpg',
          characters: [],
          order: i,
        );
        notifier.addFrame(frame);
      }

      notifier.removeFrame(1);

      final state = container.read(timelineStateProvider);
      expect(state.frames.length, equals(2));
      expect(state.frames[0].frameId, equals('frame_0'));
      expect(state.frames[1].frameId, equals('frame_2'));
    });

    test('should select and deselect frame', () {
      final notifier = container.read(timelineStateProvider.notifier);

      for (int i = 0; i < 3; i++) {
        final frame = Frame(
          frameId: 'frame_$i',
          capturedAt: DateTime.now(),
          imageUrl: '/path/to/frame_$i.jpg',
          characters: [],
          order: i,
        );
        notifier.addFrame(frame);
      }

      notifier.selectFrame(1);
      expect(container.read(timelineStateProvider).selectedFrameIndex, equals(1));

      notifier.deselectFrame();
      expect(container.read(timelineStateProvider).selectedFrameIndex, isNull);
    });

    test('should start and stop playing', () {
      final notifier = container.read(timelineStateProvider.notifier);

      expect(container.read(timelineStateProvider).isPlaying, isFalse);

      notifier.startPlaying();
      expect(container.read(timelineStateProvider).isPlaying, isTrue);

      notifier.stopPlaying();
      expect(container.read(timelineStateProvider).isPlaying, isFalse);
    });

    test('should reset to initial state', () {
      final notifier = container.read(timelineStateProvider.notifier);

      for (int i = 0; i < 3; i++) {
        final frame = Frame(
          frameId: 'frame_$i',
          capturedAt: DateTime.now(),
          imageUrl: '/path/to/frame_$i.jpg',
          characters: [],
          order: i,
        );
        notifier.addFrame(frame);
      }

      notifier.selectFrame(0);
      notifier.startPlaying();

      notifier.reset();

      final state = container.read(timelineStateProvider);
      expect(state.frames, isEmpty);
      expect(state.selectedFrameIndex, isNull);
      expect(state.isPlaying, isFalse);
    });
  });
}
