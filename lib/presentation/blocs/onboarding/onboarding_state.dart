import 'package:equatable/equatable.dart';

/// State indicating the current onboarding status and progress.
class OnboardingState extends Equatable {
  /// True if onboarding UI should be displayed.
  final bool showOnboarding;
  /// Current step index in the onboarding flow.
  final int currentStep;
  /// Total number of onboarding steps.
  final int totalSteps;
  /// Whether onboarding is completed.
  final bool isCompleted;

  const OnboardingState({
    required this.showOnboarding,
    this.currentStep = 0,
    this.totalSteps = 3,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    bool? showOnboarding,
    int? currentStep,
    int? totalSteps,
    bool? isCompleted,
  }) {
    return OnboardingState(
      showOnboarding: showOnboarding ?? this.showOnboarding,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Whether we can navigate to the next step.
  bool get canGoNext => currentStep < totalSteps - 1;

  /// Whether we can navigate to the previous step.
  bool get canGoPrevious => currentStep > 0;

  /// Whether we're on the last step.
  bool get isLastStep => currentStep == totalSteps - 1;

  /// Whether we're on the first step.
  bool get isFirstStep => currentStep == 0;

  @override
  List<Object?> get props => [showOnboarding, currentStep, totalSteps, isCompleted];
}
