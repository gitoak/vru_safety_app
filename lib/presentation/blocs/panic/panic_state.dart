import 'package:equatable/equatable.dart';

/// Base class for all panic-related states.
abstract class PanicState extends Equatable {
  const PanicState();

  @override
  List<Object?> get props => [];
}

/// Initial state when panic system is inactive.
class PanicInitial extends PanicState {
  const PanicInitial();
}

/// State when panic is being confirmed by user.
class PanicConfirming extends PanicState {
  const PanicConfirming();
}

/// State when panic mode is activated.
class PanicActivated extends PanicState {
  final DateTime timestamp;
  final String? reason;

  PanicActivated({
    DateTime? timestamp,
    this.reason,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [timestamp, reason];
  PanicActivated copyWith({
    DateTime? timestamp,
    String? reason,
  }) {
    return PanicActivated(
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
    );
  }
}

/// State representing an error in panic system.
class PanicError extends PanicState {
  final String message;

  const PanicError(this.message);

  @override
  List<Object?> get props => [message];
}
