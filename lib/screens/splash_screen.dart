import 'package:flutter/material.dart';
import '../config/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // TODO: Week 1-2 初期化処理
    // - Firebase Auth (anonymous)
    // - ARKit / ARCore 初期化テスト
    // - RevenueCat 初期化
    // - Remote Config 取得
    // - Analytics イベント記録 (app_launched)

    // 仮: 2秒後にホーム画面へ
    await Future.delayed(AppDurations.splashDuration);

    if (mounted) {
      // TODO: Navigator.of(context).pushReplacementNamed('/home');
      _showTempMessage();
    }
  }

  void _showTempMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Week 1-2 初期化フェーズ\nホーム画面はまだ実装されていません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
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
              // Logo（仮）
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusXl),
                ),
                child: const Icon(
                  Icons.movie,
                  size: 60,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'つくアニ',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: AppTypography.weightBold,
                    ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                '親子で作るAR動画クリエーター',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.white.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),

              // Loading text
              Text(
                'AR初期化中...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
