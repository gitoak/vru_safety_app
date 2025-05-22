import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Navigation destinations
enum AppPage { home, settings, sandbox }

// Events
abstract class NavEvent extends Equatable {
  const NavEvent();
  @override
  List<Object?> get props => [];
}
class NavTo extends NavEvent {
  final AppPage page;
  const NavTo(this.page);
  @override
  List<Object?> get props => [page];
}

// State
class NavState extends Equatable {
  final AppPage page;
  const NavState(this.page);
  @override
  List<Object?> get props => [page];
}

// Bloc
class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc() : super(const NavState(AppPage.home)) {
    on<NavTo>((event, emit) => emit(NavState(event.page)));
  }
}
