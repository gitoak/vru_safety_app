import 'package:equatable/equatable.dart';

/// Base class for onboarding events.
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to check if onboarding should be shown.
class CheckOnboardingStatus extends OnboardingEvent {
  const CheckOnboardingStatus();
}

/// Event to mark onboarding as completed.
class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}

/// Event to reset onboarding status (show onboarding again).
class ResetOnboarding extends OnboardingEvent {
  const ResetOnboarding();
}

/// Event to navigate to next onboarding step.
class NextOnboardingStep extends OnboardingEvent {
  const NextOnboardingStep();
}

/// Event to navigate to previous onboarding step.
class PreviousOnboardingStep extends OnboardingEvent {
  const PreviousOnboardingStep();
}

/// Event to jump to specific onboarding step.
class JumpToOnboardingStep extends OnboardingEvent {
  final int stepIndex;
  
  const JumpToOnboardingStep(this.stepIndex);
  
  @override
  List<Object?> get props => [stepIndex];
}
