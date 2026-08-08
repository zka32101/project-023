import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/firebase_service.dart';
import 'camera_screen.dart';
import 'collection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
    final achievementState = ref.watch(achievementProvider);

    if (authState.userId == null) {
      return const _InitializingView();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryStart,
              AppColors.primaryEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Text(
                          'つくアニ',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: AppTypography.weightBold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '親子で作るAR動画クリエーター',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppColors.white.withAlpha(200),
                              ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.white),
                        onPressed: () => _goToSettings(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Achievement notification
              if (achievementState.lastUnlocked != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(200),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AchievementData.fromAchievement(
                          achievementState.lastUnlocked!,
                          true,
                          null,
                        ).icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'アチーブメント達成！',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              AchievementData.fromAchievement(
                                achievementState.lastUnlocked!,
                                true,
                                null,
                              ).title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mascot character (placeholder)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withAlpha(50),
                      ),
                      child: const Icon(
                        Icons.movie,
                        size: 60,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Trial status (if applicable)
                    if (!purchaseState.isPurchased && purchaseState.isTrialActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Text(
                          '無料体験: あと ${purchaseState.trialRemainingMinutes} 分',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Main CTA Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryStart,
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          elevation: AppSizes.elevationLarge,
                        ),
                        onPressed: () => _createNewProject(context, ref),
                        child: Text(
                          '今すぐ作成',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryStart,
                            fontWeight: AppTypography.weightBold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    // Collection/Works Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.white),
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        onPressed: () => _goToCollection(context),
                        child: Text(
                          '作品を見る',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewProject(BuildContext context, WidgetRef ref) async {
    // Start trial if first use
    final purchaseState = ref.read(purchaseStateProvider);
    if (!purchaseState.isPurchased && purchaseState.trialStartTime == null) {
      ref.read(purchaseStateProvider.notifier).startTrial();
    }

    // Show loading
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now();
      final title =
          '${now.month}/${now.day} の作品 ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final projectId = await FirebaseService().createProject(title);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraScreen(projectId: projectId),
          ),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('プロジェクトの作成に失敗しました。再試行してください。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToCollection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionScreen()),
    );
  }

  void _goToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}

class _InitializingView extends ConsumerStatefulWidget {
  const _InitializingView({Key? key}) : super(key: key);

  @override
  ConsumerState<_InitializingView> createState() => _InitializingViewState();
}

class _InitializingViewState extends ConsumerState<_InitializingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signIn();
    });
  }

  void _signIn() async {
    await ref.read(authStateProvider.notifier).anonymousSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryStart,
              AppColors.primaryEnd,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'サインイン中...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
