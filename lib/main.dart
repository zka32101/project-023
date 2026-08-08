import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/revenue_cat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase already initialized or in test mode
  }

  try {
    final apiKey = Platform.isIOS
        ? AppKeys.revenueCatIos
        : AppKeys.revenueCatAndroid;
    await RevenueCatService().initialize(apiKey: apiKey);
  } catch (e) {
    // RevenueCat init failure is non-fatal; purchase features will be unavailable
  }

  runApp(
    const ProviderScope(
      child: TsukuaniApp(),
    ),
  );
}

class TsukuaniApp extends ConsumerStatefulWidget {
  const TsukuaniApp({Key? key}) : super(key: key);

  @override
  ConsumerState<TsukuaniApp> createState() => _TsukuaniAppState();
}

class _TsukuaniAppState extends ConsumerState<TsukuaniApp> {
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(AppDurations.splashDuration, () {
      if (mounted) {
        setState(() => _splashComplete = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'つくアニ',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: _splashComplete ? const HomeScreen() : const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
