import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';

final purchaseStateProvider = StateNotifierProvider<PurchaseStateNotifier, PurchaseState>((ref) {
  return PurchaseStateNotifier();
});

class PurchaseState {
  final bool isPurchased;
  final DateTime? trialStartTime;
  final int trialRemainingMinutes;
  final String? productPrice;

  PurchaseState({
    this.isPurchased = false,
    this.trialStartTime,
    this.trialRemainingMinutes = AppDurations.freeTrialMinutes,
    this.productPrice,
  });

  PurchaseState copyWith({
    bool? isPurchased,
    DateTime? trialStartTime,
    int? trialRemainingMinutes,
    String? productPrice,
  }) {
    return PurchaseState(
      isPurchased: isPurchased ?? this.isPurchased,
      trialStartTime: trialStartTime ?? this.trialStartTime,
      trialRemainingMinutes: trialRemainingMinutes ?? this.trialRemainingMinutes,
      productPrice: productPrice ?? this.productPrice,
    );
  }

  bool get isTrialActive =>
      !isPurchased && trialRemainingMinutes > 0 && trialStartTime != null;
}

class PurchaseStateNotifier extends StateNotifier<PurchaseState> {
  PurchaseStateNotifier() : super(PurchaseState());

  Timer? _trialTimer;

  void startTrial() {
    state = state.copyWith(
      trialStartTime: DateTime.now(),
      trialRemainingMinutes: AppDurations.freeTrialMinutes,
    );
    _startTrialTimer();
  }

  void _startTrialTimer() {
    _trialTimer?.cancel();
    _trialTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPurchased && state.trialStartTime != null) {
        final elapsed = DateTime.now().difference(state.trialStartTime!).inMinutes;
        final remaining = AppDurations.freeTrialMinutes - elapsed;

        if (remaining > 0) {
          state = state.copyWith(trialRemainingMinutes: remaining);
        } else {
          state = state.copyWith(trialRemainingMinutes: 0);
          _trialTimer?.cancel();
        }
      }
    });
  }

  void setPurchased(bool purchased) {
    state = state.copyWith(isPurchased: purchased);
    if (purchased) {
      _trialTimer?.cancel();
    }
  }

  void setProductPrice(String? price) {
    state = state.copyWith(productPrice: price);
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }
}
