import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  return AchievementNotifier();
});

enum Achievement {
  firstVideo,
  video5,
  video10,
  video50,
  dailyStreak3,
  dailyStreak7,
  characterUnlock5,
  characterUnlock10,
  video1Minute,
  video5Minute,
}

class AchievementData {
  final Achievement id;
  final String title;
  final String description;
  final String icon; // emoji or icon name
  final bool unlocked;
  final DateTime? unlockedAt;

  AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
  });

  factory AchievementData.fromAchievement(Achievement ach, bool unlocked, DateTime? unlockedAt) {
    switch (ach) {
      case Achievement.firstVideo:
        return AchievementData(
          id: ach,
          title: '初作品',
          description: '最初の動画を作成',
          icon: '🎬',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.video5:
        return AchievementData(
          id: ach,
          title: 'クリエーター',
          description: '5本の動画を作成',
          icon: '🌟',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.video10:
        return AchievementData(
          id: ach,
          title: 'プロデューサー',
          description: '10本の動画を作成',
          icon: '🎥',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.video50:
        return AchievementData(
          id: ach,
          title: 'マスター',
          description: '50本の動画を作成',
          icon: '👑',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.dailyStreak3:
        return AchievementData(
          id: ach,
          title: '3日連続',
          description: '3日間連続で作成',
          icon: '🔥',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.dailyStreak7:
        return AchievementData(
          id: ach,
          title: '1週間チャレンジ',
          description: '7日間連続で作成',
          icon: '⚡',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.characterUnlock5:
        return AchievementData(
          id: ach,
          title: 'コレクター',
          description: 'キャラクターを5体アンロック',
          icon: '💎',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.characterUnlock10:
        return AchievementData(
          id: ach,
          title: 'コンプリート',
          description: 'すべてのキャラクターをアンロック',
          icon: '🏆',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.video1Minute:
        return AchievementData(
          id: ach,
          title: 'ショートフィルム',
          description: '1分以上の動画を作成',
          icon: '🎞️',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      case Achievement.video5Minute:
        return AchievementData(
          id: ach,
          title: 'フル映画',
          description: '5分以上の動画を作成',
          icon: '🍿',
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
    }
  }
}

class AchievementState {
  final Map<Achievement, bool> unlockedAchievements;
  final Map<Achievement, DateTime> unlockedDates;
  final Achievement? lastUnlocked; // for notification

  AchievementState({
    this.unlockedAchievements = const {},
    this.unlockedDates = const {},
    this.lastUnlocked,
  });

  AchievementState copyWith({
    Map<Achievement, bool>? unlockedAchievements,
    Map<Achievement, DateTime>? unlockedDates,
    Achievement? lastUnlocked,
  }) {
    return AchievementState(
      unlockedAchievements:
          unlockedAchievements ?? this.unlockedAchievements,
      unlockedDates: unlockedDates ?? this.unlockedDates,
      lastUnlocked: lastUnlocked ?? this.lastUnlocked,
    );
  }

  bool isUnlocked(Achievement ach) =>
      unlockedAchievements[ach] ?? false;
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier() : super(AchievementState()) {
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = <Achievement, bool>{};
    final dates = <Achievement, DateTime>{};

    for (final ach in Achievement.values) {
      final key = 'achievement_${ach.name}';
      if (prefs.containsKey(key)) {
        unlocked[ach] = true;
        dates[ach] =
            DateTime.parse(prefs.getString('${key}_date') ?? DateTime.now().toIso8601String());
      }
    }

    state = state.copyWith(
      unlockedAchievements: unlocked,
      unlockedDates: dates,
    );
  }

  Future<void> checkAndUnlock(Achievement ach) async {
    if (state.isUnlocked(ach)) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setBool('achievement_${ach.name}', true);
    await prefs.setString('achievement_${ach.name}_date', now.toIso8601String());

    final unlocked = {...state.unlockedAchievements, ach: true};
    final dates = {...state.unlockedDates, ach: now};

    state = state.copyWith(
      unlockedAchievements: unlocked,
      unlockedDates: dates,
      lastUnlocked: ach,
    );
  }

  Future<void> checkVideoCountAchievements(int videoCount) async {
    if (videoCount >= 1 && !state.isUnlocked(Achievement.firstVideo)) {
      await checkAndUnlock(Achievement.firstVideo);
    }
    if (videoCount >= 5 && !state.isUnlocked(Achievement.video5)) {
      await checkAndUnlock(Achievement.video5);
    }
    if (videoCount >= 10 && !state.isUnlocked(Achievement.video10)) {
      await checkAndUnlock(Achievement.video10);
    }
    if (videoCount >= 50 && !state.isUnlocked(Achievement.video50)) {
      await checkAndUnlock(Achievement.video50);
    }
  }

  Future<void> checkDurationAchievements(double durationSeconds) async {
    if (durationSeconds >= 60 && !state.isUnlocked(Achievement.video1Minute)) {
      await checkAndUnlock(Achievement.video1Minute);
    }
    if (durationSeconds >= 300 && !state.isUnlocked(Achievement.video5Minute)) {
      await checkAndUnlock(Achievement.video5Minute);
    }
  }
}
