import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/nav_bloc.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/panic_bloc/panic_bloc.dart';
import 'widgets/panic_button.dart';
import 'theme.dart';
import 'navigation_config.dart';
import 'pages/onboarding_page.dart';
import 'pages/settings_page.dart'; // Import SettingsPage
import 'pages/placeholder_page.dart'; // Added
import 'pages/navigation_page.dart'; // Added

// Custom Page for Main Tab Transitions (e.g., Fade)
class MainTabPage<T> extends Page<T> {
  final Widget child;

  const MainTabPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return child;
          },
      transitionDuration: const Duration(
        milliseconds: 200,
      ), // Adjust duration as needed
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
    );
  }
}

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavBloc()),
        BlocProvider(create: (context) => SettingsBloc()),
        BlocProvider(create: (context) => PanicBloc()), // Add PanicBloc
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppRouterDelegate _routerDelegate;
  final AppRouteInformationParser _routeInformationParser = AppRouteInformationParser();
  bool _showOnboarding = true; // Default to true

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _routerDelegate = AppRouterDelegate(
      navBloc: context.read<NavBloc>(),
      // Initialize with placeholder page as the default
      initialPath: AppPath.fromScreen(navScreens.firstWhere((s) => s.route == '/placeholder')),
    );
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    setState(() {
      _showOnboarding = !onboardingComplete;
    });
  }

  void _handleOnboardingFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return MaterialApp(
        theme: appTheme,
        builder: (context, child) => AccessibilityTools(child: child),
        home: OnboardingPage(onFinish: _handleOnboardingFinish),
      );
    }

    return MaterialApp.router(
      theme: appTheme,
      builder: (context, child) => AccessibilityTools(child: child),
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}

// Helper: get NavScreenConfig from route
NavScreenConfig? navScreenConfigFromRoute(String? route) {
  if (route == null) return null;
  try {
    return navScreens.firstWhere((screen) => screen.route == route);
  } catch (e) {
    return null; // Return null if no matching route is found
  }
}

// --- AppPath (represents the current navigation state) ---
class AppPath {
  final NavScreenConfig? currentScreen;
  final List<String> subPageStack; // For sub-pages like /settings/profile

  AppPath.fromScreen(this.currentScreen, [this.subPageStack = const []]);

  factory AppPath.fromNavState(NavState navState) {
    String route;
    switch (navState.mainPage) {
      case AppPage.home:
        route = '/placeholder';
        break;
      case AppPage.settings:
        route = '/settings';
        break;
      case AppPage.sandbox:
        route = '/navigation'; // Corrected mapping for sandbox to navigation route
        break;
      // default: // Optional: handle unexpected AppPage values, though all should be covered
      //   route = '/placeholder'; 
    }
    final mainScreenConfig = navScreenConfigFromRoute(route);
    return AppPath.fromScreen(mainScreenConfig, navState.subPageStack);
  }

  String? get routePath {
    if (currentScreen == null) return '/'; // Should ideally not happen with proper initialization
    String path = currentScreen!.route;
    if (subPageStack.isNotEmpty) {
      path += '/${subPageStack.join('/')}';
    }
    return path;
  }

  static AppPath parse(String uri) {
    final parts = Uri.parse(uri).pathSegments;
    if (parts.isEmpty) {
      // Default to the first screen in navScreens (placeholder)
      return AppPath.fromScreen(navScreens.firstWhere((s) => s.route == '/placeholder'));
    }
    final mainRoute = '/${parts.first}';
    final screenConfig = navScreenConfigFromRoute(mainRoute);

    if (screenConfig != null) {
      final subStack = parts.length > 1 ? parts.sublist(1) : <String>[];
      return AppPath.fromScreen(screenConfig, subStack);
    }
    // Fallback to placeholder if route is unknown
    return AppPath.fromScreen(navScreens.firstWhere((s) => s.route == '/placeholder'));
  }
}

// --- RouterDelegate ---
class AppRouterDelegate extends RouterDelegate<AppPath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  final NavBloc navBloc;
  AppPath _currentPath;

  AppRouterDelegate({required this.navBloc, required AppPath initialPath})
      : navigatorKey = GlobalKey<NavigatorState>(),
        _currentPath = initialPath {
    navBloc.stream.listen((navState) {
      final newPath = AppPath.fromNavState(navState);
      if (newPath.routePath != _currentPath.routePath) {
        _currentPath = newPath;
        notifyListeners();
      }
    });
    // Ensure initial state is reflected
    if (_currentPath.currentScreen == null) {
      _currentPath = AppPath.fromScreen(navScreens.firstWhere((s) => s.route == '/placeholder'));
    }
  }

  @override
  AppPath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    if (_currentPath.currentScreen == null) {
      _currentPath = AppPath.fromScreen(navScreens.firstWhere((s) => s.route == '/placeholder'));
    }

    bool isMainTab = navScreens.any((screen) => screen.route == _currentPath.currentScreen?.route && screen.inNavBar);

    Widget resolvedPageContent;

    if (isMainTab) {
      AppPage currentPageEnum = AppPage.home; // Default
      if (_currentPath.currentScreen!.route == '/placeholder') {
        currentPageEnum = AppPage.home;
      } else if (_currentPath.currentScreen!.route == '/navigation') {
        currentPageEnum = AppPage.sandbox; // Assuming sandbox maps to navigation
      } else if (_currentPath.currentScreen!.route == '/settings') {
        currentPageEnum = AppPage.settings;
      }

      resolvedPageContent = MainScaffold(
        currentMainPage: currentPageEnum,
        onNavigateToMainPage: (page) {
          navBloc.add(NavTo(page));
        },
        onPushSubPage: (route) {
          navBloc.add(NavPushSubPage(route));
        },
      );
    } else {
      // For non-main tabs or sub-pages, build the page directly
      resolvedPageContent = _currentPath.currentScreen!.builder();
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        MainTabPage(
          key: ValueKey(isMainTab ? 'MainScaffold_${_currentPath.currentScreen!.route}' : _currentPath.currentScreen!.route),
          child: resolvedPageContent, 
        ),
        
        // Handle sub-pages if any (these are pushed on top of the main content)
        ..._currentPath.subPageStack.map((subRoute) {
          // Attempt to find a NavScreenConfig for the sub-page
          final subPageConfig = navScreenConfigFromRoute(subRoute);
          if (subPageConfig != null) {
            return MainTabPage(
              key: ValueKey(subRoute),
              child: subPageConfig.builder(),
            );
          }
          // Fallback for undefined sub-routes
          return MaterialPage(child: Center(child: Text('Sub Page: $subRoute - Not Implemented')));
        }),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        if (_currentPath.subPageStack.isNotEmpty) {
          navBloc.add(const NavPopSubPage());
        } else {
          // Optionally handle popping the main page (e.g., exit app or go to a default)
          // For now, let the system handle it (e.g., Android back button closes app)
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppPath configuration) async {
    _currentPath = configuration;
    // Convert AppPath to NavEvent and dispatch it
    if (configuration.currentScreen != null) {
      AppPage targetPage;
      switch (configuration.currentScreen!.route) {
        case '/placeholder':
          targetPage = AppPage.home; // Assuming placeholder maps to a conceptual "home"
          break;
        case '/navigation':
          targetPage = AppPage.sandbox; // Assuming navigation maps to a conceptual "sandbox"
          break;
        case '/settings':
          targetPage = AppPage.settings;
          break;
        default:
          // Fallback or error handling if the route is unexpected
          targetPage = AppPage.home; // Default to placeholder's conceptual home
      }
      navBloc.add(NavTo(targetPage)); // Or NavResetToMainPage if that's more appropriate
      // If there are subpages, you might need to dispatch NavPushSubPage events
      for (var subRoute in configuration.subPageStack) {
        navBloc.add(NavPushSubPage(subRoute));
      }
    }
    // notifyListeners() will be called by the navBloc.stream.listen
  }
}

// --- RouteInformationParser ---
class AppRouteInformationParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri.toString();
    return AppPath.parse(uri);
  }

  @override
  RouteInformation? restoreRouteInformation(AppPath configuration) {
    return RouteInformation(uri: Uri.parse(configuration.routePath ?? '/'));
  }
}

// Helper: get route from AppPage (ensure it exists and is correct)
String routeFromAppPage(AppPage page) {
  final config = navScreens.firstWhere(
    (s) => s.label.toLowerCase() == page.name.toLowerCase() && s.inNavBar,
    // Fallback if label matching fails (e.g. if AppPage enum names differ from labels)
    // A more robust mapping might be needed if names/labels diverge significantly.
    orElse: () =>
        navScreens[page
            .index], // This assumes AppPage enum order matches navScreens order for main pages
  );
  return config.route;
}

// --- MainScaffold with BottomNavigationBar ---
class MainScaffold extends StatefulWidget {
  final AppPage currentMainPage;
  final ValueChanged<AppPage> onNavigateToMainPage;
  final ValueChanged<String> onPushSubPage; // Callback to push a sub-page

  const MainScaffold({
    super.key,
    required this.currentMainPage,
    required this.onNavigateToMainPage,
    required this.onPushSubPage,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Use PageStorageKeys for each main page to preserve their state
  final PageStorageBucket _bucket = PageStorageBucket();
  final Key _placeholderKey = const PageStorageKey<String>('placeholderPage'); // Renamed for clarity
  final Key _settingsKey = const PageStorageKey<String>('settingsPage');
  final Key _navigationKey = const PageStorageKey<String>('navigationPage'); // Renamed for clarity

  // Define the correct order of AppPage enums as they appear in the BottomNavBar
  final List<AppPage> _bottomNavOrder = [
    AppPage.home,     // Corresponds to Placeholder (index 0)
    AppPage.sandbox,  // Corresponds to Navigation (index 1)
    AppPage.settings  // Corresponds to Settings (index 2)
  ];

  @override
  Widget build(BuildContext context) {
    final mainPageConfig = navScreenConfigFromRoute(
      routeFromAppPage(widget.currentMainPage),
    );
    bool showBottomNavBar = mainPageConfig?.inNavBar ?? false;

    // Determine the current body widget based on currentMainPage
    // We wrap each main page view in PageStorage to preserve state
    Widget currentPageWidget;
    switch (widget.currentMainPage) {
      case AppPage.home:
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: PlaceholderPage(key: _placeholderKey), // Use updated key
        );
        break;
      case AppPage.settings:
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: SettingsPage(key: _settingsKey),
        );
        break;
      case AppPage.sandbox:
        // For SandboxPage, we need to pass the onPushSubPage callback
        // This requires modifying SandboxPage to accept this callback.
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: NavigationPage(
            key: _navigationKey, // Use updated key
          ),
        );
        break;
    }
    return Scaffold(
      // AppBar might be part of individual pages or a common one here
      // For now, let individual pages (including sub-pages) define their own AppBars
      body: currentPageWidget,
      floatingActionButton: PanicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: showBottomNavBar
          ? BottomNavigationBar(
              items: navScreens
                  .where((s) => s.inNavBar)
                  .map(
                    (s) => BottomNavigationBarItem(
                      icon: Icon(s.icon),
                      label: s.label,
                    ),
                  )
                  .toList(),
              currentIndex: _bottomNavOrder.indexOf(widget.currentMainPage), // Use defined order for currentIndex
              onTap: (index) {
                widget.onNavigateToMainPage(_bottomNavOrder[index]); // Use defined order for onTap
              },
            )
          : null,
    );
  }
}
