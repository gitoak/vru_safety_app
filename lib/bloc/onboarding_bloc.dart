import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class CheckOnboardingStatus extends OnboardingEvent {}
class CompleteOnboarding extends OnboardingEvent {}
class ResetOnboarding extends OnboardingEvent {}

// State
class OnboardingState extends Equatable {
  final bool showOnboarding;
  const OnboardingState({required this.showOnboarding});
  @override
  List<Object?> get props => [showOnboarding];
}

// Bloc
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState(showOnboarding: true)) {
    on<CheckOnboardingStatus>(_onCheckOnboardingStatus);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ResetOnboarding>(_onResetOnboarding);
  }

  Future<void> _onCheckOnboardingStatus(CheckOnboardingStatus event, Emitter<OnboardingState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    emit(OnboardingState(showOnboarding: !onboardingComplete));
  }

  Future<void> _onCompleteOnboarding(CompleteOnboarding event, Emitter<OnboardingState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    emit(const OnboardingState(showOnboarding: false));
  }

  Future<void> _onResetOnboarding(ResetOnboarding event, Emitter<OnboardingState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', false);
    emit(const OnboardingState(showOnboarding: true));
  }
}
