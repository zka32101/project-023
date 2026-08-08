import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuani/providers/purchase_provider.dart';
import 'package:tsukuani/config/constants.dart';

void main() {
  group('PurchaseStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be not purchased with full trial', () {
      final state = container.read(purchaseStateProvider);
      expect(state.isPurchased, isFalse);
      expect(state.trialRemainingMinutes, equals(AppDurations.freeTrialMinutes));
      expect(state.isTrialActive, isFalse);
    });

    test('should start trial', () {
      final notifier = container.read(purchaseStateProvider.notifier);
      notifier.startTrial();

      final state = container.read(purchaseStateProvider);
      expect(state.trialStartTime, isNotNull);
      expect(state.trialRemainingMinutes, equals(AppDurations.freeTrialMinutes));
    });

    test('should set purchased flag', () {
      final notifier = container.read(purchaseStateProvider.notifier);
      notifier.setPurchased(true);

      final state = container.read(purchaseStateProvider);
      expect(state.isPurchased, isTrue);
    });

    test('should set product price', () {
      final notifier = container.read(purchaseStateProvider.notifier);
      notifier.setProductPrice('¥600');

      final state = container.read(purchaseStateProvider);
      expect(state.productPrice, equals('¥600'));
    });

    test('should mark trial as active after starting', () async {
      final notifier = container.read(purchaseStateProvider.notifier);
      notifier.startTrial();

      // Immediately after start, trial should be active
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(purchaseStateProvider);
      expect(state.isTrialActive, isTrue);
    });
  });
}
