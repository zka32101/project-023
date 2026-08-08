import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

enum OnboardingStep {
  tapToShoot,
  dragCharacter,
  fpsControl,
  goToTimeline,
}

class OnboardingState {
  final bool completedInitialTutorial;
  final Set<OnboardingStep> completedSteps;

  OnboardingState({
    this.completedInitialTutorial = false,
    this.completedSteps = const {},
  });

  OnboardingState copyWith({
    bool? completedInitialTutorial,
    Set<OnboardingStep>? completedSteps,
  }) {
    return OnboardingState(
      completedInitialTutorial:
          completedInitialTutorial ?? this.completedInitialTutorial,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState()) {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (completed) {
      state = state.copyWith(completedInitialTutorial: true);
    }
  }

  Future<void> completeInitialTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    state = state.copyWith(completedInitialTutorial: true);
  }

  void markStepCompleted(OnboardingStep step) {
    final updated = {...state.completedSteps, step};
    state = state.copyWith(completedSteps: updated);
  }

  bool isStepActive(OnboardingStep step) {
    return !state.completedInitialTutorial &&
        !state.completedSteps.contains(step);
  }
}
