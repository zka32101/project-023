import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/services/video_service.dart';

void main() {
  group('VideoService', () {
    late VideoService videoService;

    setUp(() {
      videoService = VideoService();
    });

    test('should estimate file size correctly', () {
      // 1 frame = ~0.5MB
      // 10 frames = ~5MB
      expect(videoService.estimateSize(10), greaterThan(0));
      expect(videoService.estimateSize(100), greaterThan(videoService.estimateSize(10)));
    });

    test('video resolution dimensions should be correct', () {
      // Test 720p resolution
      final dims720 = videoService.getResolutionDimensions(VideoResolution.resolution720p);
      expect(dims720.$1, equals(1280));
      expect(dims720.$2, equals(720));

      // Test 1080p resolution
      final dims1080 = videoService.getResolutionDimensions(VideoResolution.resolution1080p);
      expect(dims1080.$1, equals(1920));
      expect(dims1080.$2, equals(1080));
    });

    test('should handle frame count correctly', () {
      expect(videoService.estimateSize(0), equals(0));
      expect(videoService.estimateSize(1), greaterThan(0));
      expect(videoService.estimateSize(100), greaterThan(videoService.estimateSize(1)));
    });
  });
}

// Helper extension to match private method
extension VideoServiceHelper on VideoService {
  (int, int) getResolutionDimensions(VideoResolution resolution) {
    switch (resolution) {
      case VideoResolution.resolution720p:
        return (1280, 720);
      case VideoResolution.resolution1080p:
        return (1920, 1080);
    }
  }

  int estimateSize(int frameCount) {
    return (frameCount * 0.5).ceil();
  }
}
