import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/providers/auth_provider.dart';
import 'package:tsukuani/providers/purchase_provider.dart';
import 'package:tsukuani/screens/home_screen.dart';

// Returns a HomeScreen with auth pre-set to a logged-in user.
Widget _buildHomeScreen({bool isPurchased = false, bool trialActive = false}) {
  final purchaseOverride = purchaseStateProvider.overrideWith((ref) {
    final notifier = PurchaseStateNotifier();
    if (isPurchased) notifier.setPurchased(true);
    if (trialActive) notifier.startTrial();
    return notifier;
  });

  final authOverride = authStateProvider.overrideWith(
    (ref) => AuthNotifier.withState(AuthState(userId: 'test-user-123')),
  );

  return ProviderScope(
    overrides: [authOverride, purchaseOverride],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('HomeScreen shows app title and CTA buttons when signed in',
      (tester) async {
    await tester.pumpWidget(_buildHomeScreen());
    await tester.pump();

    expect(find.text('つくアニ'), findsOneWidget);
    expect(find.text('今すぐ作成'), findsOneWidget);
    expect(find.text('作品を見る'), findsOneWidget);
  });

  testWidgets('HomeScreen shows trial badge when trial is active',
      (tester) async {
    await tester.pumpWidget(_buildHomeScreen(trialActive: true));
    await tester.pump();

    expect(find.textContaining('無料体験'), findsOneWidget);
  });

  testWidgets('HomeScreen hides trial badge when not in trial', (tester) async {
    await tester.pumpWidget(_buildHomeScreen());
    await tester.pump();

    expect(find.textContaining('無料体験'), findsNothing);
  });

  testWidgets('HomeScreen shows loading screen when userId is null',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => AuthNotifier.withState(AuthState()),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('サインイン中...'), findsOneWidget);
  });
}
