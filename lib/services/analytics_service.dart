import 'package:firebase_analytics/firebase_analytics.dart';
import '../config/constants.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logAppLaunched() async {
    await _analytics.logEvent(
      name: AnalyticsEvents.appLaunched,
    );
  }

  Future<void> logFreeTrialStarted({
    required String deviceModel,
    required String osVersion,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.freeTrialStarted,
      parameters: {
        'device_model': deviceModel,
        'os_version': osVersion,
      },
    );
  }

  Future<void> logAhaMomentReached({
    required int frameCount,
    required int elapsedTimeSec,
    required bool isPurchased,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.ahaMomentReached,
      parameters: {
        'frame_count': frameCount,
        'elapsed_time_sec': elapsedTimeSec,
        'trial_or_purchased': isPurchased ? 'purchased' : 'trial',
      },
    );
  }

  Future<void> logPaywallViewed({
    required int trialRemainingMin,
    required String variant,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.paywallViewed,
      parameters: {
        'trial_remaining_min': trialRemainingMin,
        'variant': variant,
      },
    );
  }

  Future<void> logPurchaseCompleted({
    required int priceJPY,
    required String purchaseMethod,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.purchaseCompleted,
      parameters: {
        'price_jpy': priceJPY,
        'purchase_method': purchaseMethod,
      },
    );
  }

  Future<void> logCollectionViewed({
    required bool isPurchased,
    required int itemCount,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.collectionViewed,
      parameters: {
        'trial_or_purchased': isPurchased ? 'purchased' : 'trial',
        'item_count': itemCount,
      },
    );
  }

  Future<void> logCharacterUnlocked({
    required String characterId,
    required int unlockCountTotal,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.characterUnlocked,
      parameters: {
        'character_id': characterId,
        'unlock_count_total': unlockCountTotal,
      },
    );
  }

  Future<void> logVideoExported({
    required String resolution,
    required int frameCount,
    required int fps,
    required double fileSizeMB,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.videoExported,
      parameters: {
        'resolution': resolution,
        'frame_count': frameCount,
        'fps': fps,
        'file_size_mb': fileSizeMB.toStringAsFixed(2),
      },
    );
  }

  Future<void> logProjectCreated({
    required bool isPurchased,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.projectCreated,
      parameters: {
        'trial_or_purchased': isPurchased ? 'purchased' : 'trial',
      },
    );
  }
}
