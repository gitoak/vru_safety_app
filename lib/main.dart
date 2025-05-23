import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/nav_bloc.dart';
import 'bloc/settings_bloc.dart';
import 'theme.dart';
import 'navigation_config.dart';
import 'pages/onboarding_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOnboarding = true; // Assume onboarding is needed until checked
  bool _isLoading = true; // To show loading indicator while checking prefs

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingComplete;
        _isLoading = false;
      });
    }
  }

  void _handleOnboardingFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp( // Apply appTheme here
        theme: appTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_showOnboarding) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavBloc()), // NavBloc might not be strictly needed here
          BlocProvider(create: (_) => SettingsBloc()),
        ],
        child: MaterialApp( // Apply appTheme here
          theme: appTheme,
          home: OnboardingPage(
            onFinish: _handleOnboardingFinish,
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavBloc()),
        BlocProvider(create: (_) => SettingsBloc()),
      ],
      child: MaterialApp.router(
        title: 'VRU Safety App', // Changed title
        theme: appTheme,
        routerDelegate: AppRouterDelegate(),
        routeInformationParser: AppRouteInformationParser(),
      ),
    );
  }
}

// Helper: get AppPage from route
AppPage? appPageFromRoute(String? route) {
  final config = navScreens.firstWhere(
    (s) => s.route == route,
    orElse: () => navScreens[0],
  );
  return AppPage.values[navScreens.indexOf(config)];
}

// Helper: get route from AppPage
String routeFromAppPage(AppPage page) {
  return navScreens[page.index].route;
}

// --- RouterDelegate ---
class AppRouterDelegate extends RouterDelegate<AppPage>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPage> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppPage? _currentPage;

  @override
  AppPage? get currentConfiguration => _currentPage;

  @override
  Widget build(BuildContext context) {
    final navState = context.watch<NavBloc>().state;
    _currentPage = navState.page;
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(child: MainScaffold(selected: navState.page)),
      ],
      onDidRemovePage: (page) {
        // No-op: default behavior, required for Navigator.pages API
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppPage configuration) async {
    _currentPage = configuration;
    notifyListeners();
  }
}

// --- RouteInformationParser ---
class AppRouteInformationParser extends RouteInformationParser<AppPage> {
  @override
  Future<AppPage> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    final config = navScreens.firstWhere(
      (s) => s.route == uri.path,
      orElse: () => navScreens[0],
    );
    return AppPage.values[navScreens.indexOf(config)];
  }

  @override
  RouteInformation? restoreRouteInformation(AppPage configuration) {
    return RouteInformation(uri: Uri.parse(navScreens[configuration.index].route));
  }
}

// --- MainScaffold with BottomNavigationBar ---
class MainScaffold extends StatelessWidget {
  final AppPage selected;
  const MainScaffold({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final navBarScreens = navScreens.where((s) => s.inNavBar).toList();
    return Scaffold(
      body: navScreens[selected.index].builder(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navBarScreens.indexWhere((s) => s.route == navScreens[selected.index].route),
        onTap: (i) {
          context.read<NavBloc>().add(NavTo(AppPage.values[navScreens.indexOf(navBarScreens[i])]));
        },
        items: [
          for (final s in navBarScreens)
            BottomNavigationBarItem(icon: Icon(s.icon), label: s.label),
        ],
      ),
    );
  }
}
