import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Navigation destinations
enum AppPage { placeholder, navigation, settings }

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

class NavPushSubPage extends NavEvent {
  final String route;
  const NavPushSubPage(this.route);
  @override
  List<Object?> get props => [route];
}

class NavPopSubPage extends NavEvent {
  const NavPopSubPage();
}

class NavResetToMainPage extends NavEvent {
  final AppPage page;
  const NavResetToMainPage(this.page);
  @override
  List<Object?> get props => [page];
}

// State
class NavState extends Equatable {
  final AppPage mainPage;
  final List<String> subPageStack; // Stack of sub-page routes

  const NavState({
    required this.mainPage,
    this.subPageStack = const [],
  });

  bool get hasSubPages => subPageStack.isNotEmpty;
  String? get currentSubPage => subPageStack.isNotEmpty ? subPageStack.last : null;

  NavState copyWith({
    AppPage? mainPage,
    List<String>? subPageStack,
  }) {
    return NavState(
      mainPage: mainPage ?? this.mainPage,
      subPageStack: subPageStack ?? this.subPageStack,
    );
  }

  @override
  List<Object?> get props => [mainPage, subPageStack];
}

// Bloc
class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc() : super(const NavState(mainPage: AppPage.placeholder)) {
    on<NavTo>(_onNavTo);
    on<NavPushSubPage>(_onNavPushSubPage);
    on<NavPopSubPage>(_onNavPopSubPage);
    on<NavResetToMainPage>(_onNavResetToMainPage);
  }

  void _onNavTo(NavTo event, Emitter<NavState> emit) {
    // When navigating to a main page, clear any sub-page stack
    emit(NavState(mainPage: event.page, subPageStack: const []));
  }

  void _onNavPushSubPage(NavPushSubPage event, Emitter<NavState> emit) {
    // Add sub-page to the stack
    final newStack = List<String>.from(state.subPageStack)..add(event.route);
    emit(state.copyWith(subPageStack: newStack));
  }

  void _onNavPopSubPage(NavPopSubPage event, Emitter<NavState> emit) {
    if (state.subPageStack.isNotEmpty) {
      // Remove the last sub-page from the stack
      final newStack = List<String>.from(state.subPageStack)..removeLast();
      emit(state.copyWith(subPageStack: newStack));
    }
  }

  void _onNavResetToMainPage(NavResetToMainPage event, Emitter<NavState> emit) {
    // Reset to a specific main page and clear sub-page stack
    emit(NavState(mainPage: event.page, subPageStack: const []));
  }

  // Convenience methods for programmatic navigation
  void navigateToMainPage(AppPage page) => add(NavTo(page));
  void pushSubPage(String route) => add(NavPushSubPage(route));
  void popSubPage() => add(NavPopSubPage());
  void resetToMainPage(AppPage page) => add(NavResetToMainPage(page));
}
