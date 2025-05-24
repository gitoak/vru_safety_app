import 'package:equatable/equatable.dart';

/// Base class for all panic-related events.
abstract class PanicEvent extends Equatable {
  const PanicEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger panic mode.
class TriggerPanic extends PanicEvent {
  final String? reason;

  const TriggerPanic({this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Event to reset panic mode.
class ResetPanic extends PanicEvent {
  const ResetPanic();
}

/// Event to start panic confirmation process.
class StartPanicConfirmation extends PanicEvent {
  const StartPanicConfirmation();
}

/// Event to cancel panic confirmation.
class CancelPanicConfirmation extends PanicEvent {
  const CancelPanicConfirmation();
}
