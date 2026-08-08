import 'package:vibration/vibration.dart';

enum HapticFeedbackType {
  lightTap,
  mediumTap,
  heavyTap,
  shootSuccess,
  completeCelebration,
  characterUnlock,
  error,
}

class HapticService {
  static final HapticService _instance = HapticService._internal();

  factory HapticService() {
    return _instance;
  }

  HapticService._internal();

  bool _isAvailable = false;

  Future<void> initialize() async {
    _isAvailable = await Vibration.hasVibrator() ?? false;
  }

  Future<void> trigger(HapticFeedbackType type) async {
    if (!_isAvailable) return;

    switch (type) {
      case HapticFeedbackType.lightTap:
        await Vibration.vibrate(duration: 50);
        break;

      case HapticFeedbackType.mediumTap:
        await Vibration.vibrate(duration: 100);
        break;

      case HapticFeedbackType.heavyTap:
        await Vibration.vibrate(duration: 150);
        break;

      case HapticFeedbackType.shootSuccess:
        // Short tap pattern
        await Vibration.vibrate(duration: 80);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 80);
        break;

      case HapticFeedbackType.completeCelebration:
        // Pattern: long, short, short, long
        await Vibration.vibrate(duration: 200);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 200);
        break;

      case HapticFeedbackType.characterUnlock:
        // Success pattern: three taps
        await Vibration.vibrate(duration: 80);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 80);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 80);
        break;

      case HapticFeedbackType.error:
        // Warning pattern: double tap
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 100);
        break;
    }
  }
}
