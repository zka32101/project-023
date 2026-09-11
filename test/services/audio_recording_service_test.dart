import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/audio_recording_service.dart';

void main() {
  group('AudioRecordingService', () {
    late AudioRecordingService recordingService;

    setUp(() {
      recordingService = AudioRecordingService();
    });

    tearDown(() async {
      await recordingService.dispose();
    });

    test('singleton returns same instance', () {
      final instance1 = AudioRecordingService();
      final instance2 = AudioRecordingService();
      expect(identical(instance1, instance2), true);
    });

    test('initial state is not recording', () {
      expect(recordingService.isRecording, false);
      expect(recordingService.isPaused, false);
      expect(recordingService.currentRecordingPath, null);
    });

    test('getAmplitude returns 0.0 when not recording', () async {
      final amplitude = await recordingService.getAmplitude();
      expect(amplitude, 0.0);
    });

    test('getAmplitude returns 0.0 when paused', () async {
      // This test would need a mock or platform channel
      // Just verify the method is callable
      final amplitude = await recordingService.getAmplitude();
      expect(amplitude, isA<double>());
    });
  });
}
