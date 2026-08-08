import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/providers/export_provider.dart';
import 'package:tsukuani/providers/purchase_provider.dart';
import 'package:tsukuani/screens/export_screen.dart';

Widget _buildExportScreen({bool isPurchased = false}) {
  return ProviderScope(
    overrides: [
      purchaseStateProvider.overrideWith((ref) {
        final notifier = PurchaseStateNotifier();
        if (isPurchased) notifier.setPurchased(true);
        return notifier;
      }),
      exportStateProvider.overrideWith((ref) => ExportStateNotifier()),
    ],
    child: const MaterialApp(
      home: ExportScreen(
        projectId: 'test-project-id',
        frameCount: 10,
        fps: 10,
      ),
    ),
  );
}

void main() {
  testWidgets('ExportScreen shows file info card', (tester) async {
    await tester.pumpWidget(_buildExportScreen());
    await tester.pump();

    expect(find.text('動画を出力する'), findsOneWidget);
    expect(find.text('ファイル情報:'), findsOneWidget);
    expect(find.text('10'), findsWidgets); // frameCount and fps both show "10"
    expect(find.text('1.00秒'), findsOneWidget);
  });

  testWidgets('ExportScreen shows paywall when not purchased', (tester) async {
    await tester.pumpWidget(_buildExportScreen(isPurchased: false));
    await tester.pump();

    expect(find.text('まだ書出できません'), findsOneWidget);
    expect(find.text('今すぐ購入'), findsOneWidget);
    expect(find.text('後でする'), findsOneWidget);
  });

  testWidgets('ExportScreen shows export button when purchased', (tester) async {
    await tester.pumpWidget(_buildExportScreen(isPurchased: true));
    await tester.pump();

    expect(find.text('書き出しを開始'), findsOneWidget);
    expect(find.text('まだ書出できません'), findsNothing);
  });

  testWidgets('ExportScreen shows 1080p resolution when purchased',
      (tester) async {
    await tester.pumpWidget(_buildExportScreen(isPurchased: true));
    await tester.pump();

    expect(find.text('1080p (推奨)'), findsOneWidget);
  });

  testWidgets('ExportScreen shows 720p resolution in free tier', (tester) async {
    await tester.pumpWidget(_buildExportScreen(isPurchased: false));
    await tester.pump();

    expect(find.text('720p'), findsOneWidget);
  });
}
