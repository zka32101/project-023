import 'package:flutter/material.dart';

// Color Constants
class AppColors {
  // Primary - グラデーション用基調色（教科色は後で決定）
  static const Color primaryStart = Color(0xFF6366F1);
  static const Color primaryEnd = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFFFECA57);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color mediumGrey = Color(0xFFD1D5DB);
  static const Color darkGrey = Color(0xFF374151);
  static const Color black = Color(0xFF1F2937);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dark Mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
}

// Size Constants
class AppSizes {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Button & Tap Target
  static const double minTapTarget = 44.0;
  static const double shootButtonSize = 60.0;

  // Elevation / Shadow
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
}

// Typography Constants
class AppTypography {
  // Font Sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 24.0;
  static const double fontSizeXxl = 32.0;

  // Font Weights
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
}

// Duration Constants
class AppDurations {
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Trial Duration
  static const int freeTrialMinutes = 60;
}

// Price Constants
class AppPrices {
  static const int priceJPY = 600;
}

// AR & Camera Constants
class ARConstants {
  static const int maxFramesFree = 100;
  static const int ahaFrameThreshold = 3; // Aha Moment = 3フレーム
  static const List<int> fpsPresets = [1, 5, 10, 20, 30];
  static const int defaultFPS = 10;
}

// Firestore Constants
class FirestoreConstants {
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String framesCollection = 'frames';
  static const String arCharactersCollection = 'ar_characters';
  static const String appConfigCollection = 'app_config';
}

// API Keys (replace with real keys before release)
class AppKeys {
  static const String revenueCatAndroid = 'REVENUECAT_ANDROID_API_KEY';
  static const String revenueCatIos = 'REVENUECAT_IOS_API_KEY';
}

// Analytics Event Names
class AnalyticsEvents {
  static const String appLaunched = 'app_launched';
  static const String freeTrialStarted = 'free_trial_started';
  static const String ahaMomentReached = 'aha_moment_reached';
  static const String paywallViewed = 'paywall_viewed';
  static const String purchaseCompleted = 'purchase_completed';
  static const String collectionViewed = 'collection_viewed';
  static const String characterUnlocked = 'character_unlocked';
  static const String videoExported = 'video_exported';
  static const String projectCreated = 'project_created';
}
