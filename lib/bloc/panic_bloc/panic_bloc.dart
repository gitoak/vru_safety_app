import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

part 'panic_events.dart';
part 'panic_states.dart';

class PanicBloc extends Bloc<PanicEvent, PanicState> {
  Timer? _confirmationTimer;
  static const Duration confirmationTimeout = Duration(seconds: 10);

  PanicBloc() : super(PanicInitial()) {
    on<StartPanicConfirmation>(_onStartPanicConfirmation);
    on<CancelPanicConfirmation>(_onCancelPanicConfirmation);
    on<TriggerPanic>(_onTriggerPanic);
    on<ResetPanic>(_onResetPanic);
  }

  void _onStartPanicConfirmation(StartPanicConfirmation event, Emitter<PanicState> emit) {
    emit(PanicConfirming());
    
    // Auto-cancel confirmation after timeout
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(confirmationTimeout, () {
      add(CancelPanicConfirmation());
    });
  }

  void _onCancelPanicConfirmation(CancelPanicConfirmation event, Emitter<PanicState> emit) {
    _confirmationTimer?.cancel();
    emit(PanicInitial());
  }

  void _onTriggerPanic(TriggerPanic event, Emitter<PanicState> emit) {
    _confirmationTimer?.cancel();
    emit(PanicActivated(timestamp: DateTime.now()));
  }

  void _onResetPanic(ResetPanic event, Emitter<PanicState> emit) {
    _confirmationTimer?.cancel();
    emit(PanicInitial());
  }

  @override
  Future<void> close() {
    _confirmationTimer?.cancel();
    return super.close();
  }
}