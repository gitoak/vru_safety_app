import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// BLoC that manages the onboarding flow and persistence.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  OnboardingBloc() : super(const OnboardingState(showOnboarding: true)) {
    on<CheckOnboardingStatus>(_onCheckOnboardingStatus);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ResetOnboarding>(_onResetOnboarding);
    on<NextOnboardingStep>(_onNextOnboardingStep);
    on<PreviousOnboardingStep>(_onPreviousOnboardingStep);
    on<JumpToOnboardingStep>(_onJumpToOnboardingStep);

    // Check onboarding status on initialization
    add(const CheckOnboardingStatus());
  }

  /// Loads onboarding completion status from storage and updates state.
  Future<void> _onCheckOnboardingStatus(
    CheckOnboardingStatus event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
      emit(state.copyWith(
        showOnboarding: !onboardingComplete,
        isCompleted: onboardingComplete,
      ));
    } catch (e) {
      // If there's an error loading preferences, show onboarding
      emit(state.copyWith(showOnboarding: true, isCompleted: false));
    }
  }

  /// Marks onboarding as completed in persistent storage.
  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      emit(state.copyWith(
        showOnboarding: false,
        isCompleted: true,
      ));
    } catch (e) {
      // Handle error saving onboarding completion
      emit(state.copyWith(showOnboarding: true, isCompleted: false));
    }
  }

  /// Resets onboarding status (shows onboarding again).
  Future<void> _onResetOnboarding(
    ResetOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, false);
      emit(state.copyWith(
        showOnboarding: true,
        currentStep: 0,
        isCompleted: false,
      ));
    } catch (e) {
      // Handle error resetting onboarding
      emit(state.copyWith(
        showOnboarding: true,
        currentStep: 0,
        isCompleted: false,
      ));
    }
  }

  /// Navigates to the next onboarding step.
  void _onNextOnboardingStep(
    NextOnboardingStep event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.canGoNext) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  /// Navigates to the previous onboarding step.
  void _onPreviousOnboardingStep(
    PreviousOnboardingStep event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.canGoPrevious) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  /// Jumps to a specific onboarding step.
  void _onJumpToOnboardingStep(
    JumpToOnboardingStep event,
    Emitter<OnboardingState> emit,
  ) {
    if (event.stepIndex >= 0 && event.stepIndex < state.totalSteps) {
      emit(state.copyWith(currentStep: event.stepIndex));
    }
  }
}
