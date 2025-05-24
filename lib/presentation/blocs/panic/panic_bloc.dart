import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'panic_event.dart';
import 'panic_state.dart';

/// BLoC that manages panic confirmation and activation flow.
class PanicBloc extends Bloc<PanicEvent, PanicState> {
  /// Timer for auto-canceling the confirmation after timeout.
  Timer? _confirmationTimer;

  /// Timeout duration to wait for user confirmation.
  static const Duration confirmationTimeout = Duration(seconds: 10);

  PanicBloc() : super(const PanicInitial()) {
    on<StartPanicConfirmation>(_onStartPanicConfirmation);
    on<CancelPanicConfirmation>(_onCancelPanicConfirmation);
    on<TriggerPanic>(_onTriggerPanic);
    on<ResetPanic>(_onResetPanic);
  }

  /// Begins the confirmation state and starts the timeout.
  void _onStartPanicConfirmation(
    StartPanicConfirmation event,
    Emitter<PanicState> emit,
  ) {
    emit(const PanicConfirming());
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(confirmationTimeout, () {
      add(const CancelPanicConfirmation());
    });
  }

  /// Cancels the confirmation and returns to the initial state.
  void _onCancelPanicConfirmation(
    CancelPanicConfirmation event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(const PanicInitial());
  }

  /// Activates panic immediately with a timestamp.
  void _onTriggerPanic(
    TriggerPanic event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(PanicActivated(
      timestamp: DateTime.now(),
      reason: event.reason,
    ));
  }

  /// Resets panic back to the initial state.
  void _onResetPanic(
    ResetPanic event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(const PanicInitial());
  }

  @override
  Future<void> close() {
    _confirmationTimer?.cancel();
    return super.close();
  }
}
