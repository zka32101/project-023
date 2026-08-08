import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final socialShareProvider = Provider((ref) => SocialShareService());

class SocialShareService {
  /// Generate shareable link for a project
  /// In production, use Firebase Dynamic Links
  /// For now, return a deep link format
  String generateShareLink(String projectId) {
    return 'https://tsukuani.app/watch/$projectId';
  }

  /// Generate share text with project details
  String generateShareText(String projectTitle, int frameCount, double duration) {
    return '''
つくアニで「$projectTitle」を作りました！

📹 $frameCount フレーム
⏱️ ${duration.toStringAsFixed(1)} 秒

親子で作るAR動画クリエーター「つくアニ」で、あなたも動画を作ってみませんか？

🔗 Google Play: https://play.google.com/store/apps/details?id=com.example.tsukuani
🔗 App Store: https://apps.apple.com/app/tsukuani

#つくアニ #コマ撮り #AR動画 #親子で作ろう
''';
  }

  /// Simulated Firebase Analytics event
  void trackShareEvent(String projectId, String platform) {
    // In production: FirebaseAnalytics.instance.logShare(...)
    AppLogger.info('Share tracked: projectId=$projectId, platform=$platform');
  }
}
