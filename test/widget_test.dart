import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );
    await tester.pump(); // one frame to render

    expect(find.text('つくアニ'), findsOneWidget);

    // Advance time past the 2-second delay so no pending timers remain
    await tester.pump(const Duration(seconds: 3));
  });
}
