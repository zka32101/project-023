import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuani/providers/camera_provider.dart';
import 'package:tsukuani/config/constants.dart';

void main() {
  group('CameraStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be correct', () {
      final state = container.read(cameraStateProvider);
      expect(state.onionSkinEnabled, isTrue);
      expect(state.fpsPreset, equals(ARConstants.defaultFPS));
      expect(state.frameCount, equals(0));
      expect(state.placedCharacters, isEmpty);
      expect(state.isAhaMoment, isFalse);
    });

    test('should toggle onion skin', () {
      final notifier = container.read(cameraStateProvider.notifier);
      notifier.toggleOnionSkin();

      var state = container.read(cameraStateProvider);
      expect(state.onionSkinEnabled, isFalse);

      notifier.toggleOnionSkin();
      state = container.read(cameraStateProvider);
      expect(state.onionSkinEnabled, isTrue);
    });

    test('should set FPS preset', () {
      final notifier = container.read(cameraStateProvider.notifier);
      notifier.setFpsPreset(20);

      final state = container.read(cameraStateProvider);
      expect(state.fpsPreset, equals(20));
    });

    test('should not set invalid FPS', () {
      final notifier = container.read(cameraStateProvider.notifier);
      notifier.setFpsPreset(99);

      final state = container.read(cameraStateProvider);
      expect(state.fpsPreset, equals(ARConstants.defaultFPS));
    });

    test('should toggle grid guide', () {
      final notifier = container.read(cameraStateProvider.notifier);
      expect(container.read(cameraStateProvider).gridGuideEnabled, isFalse);

      notifier.toggleGridGuide();
      expect(container.read(cameraStateProvider).gridGuideEnabled, isTrue);
    });

    test('should record frame and increment count', () {
      final notifier = container.read(cameraStateProvider.notifier);

      expect(container.read(cameraStateProvider).frameCount, equals(0));
      expect(container.read(cameraStateProvider).isAhaMoment, isFalse);

      notifier.recordFrame();
      notifier.recordFrame();
      notifier.recordFrame();

      final state = container.read(cameraStateProvider);
      expect(state.frameCount, equals(3));
      expect(state.isAhaMoment, isTrue);
    });

    test('should reset to initial state', () {
      final notifier = container.read(cameraStateProvider.notifier);
      notifier.recordFrame();
      notifier.recordFrame();
      notifier.toggleOnionSkin();
      notifier.setFpsPreset(20);

      notifier.reset();

      final state = container.read(cameraStateProvider);
      expect(state.frameCount, equals(0));
      expect(state.onionSkinEnabled, isTrue);
      expect(state.fpsPreset, equals(ARConstants.defaultFPS));
    });
  });
}
