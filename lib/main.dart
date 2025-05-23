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
import 'pages/not_found_page.dart'; // Import NotFoundPage
import 'pages/home_page.dart'; // Import HomePage
import 'pages/settings_page.dart'; // Import SettingsPage
import 'pages/sandbox_page.dart'; // Import SandboxPage

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
  bool _showOnboarding = true;
  bool _isLoading = true;
  late AppRouterDelegate _routerDelegate;
  late AppRouteInformationParser _routeInformationParser;

  @override
  void initState() {
    super.initState();
    _routerDelegate = AppRouterDelegate(context.read<NavBloc>());
    _routeInformationParser = AppRouteInformationParser();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    setState(() {
      _showOnboarding = !onboardingComplete;
      _isLoading = false;
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
    if (_isLoading) {
      return MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

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
    return navScreens.firstWhere((config) => config.route == route);
  } catch (e) {
    return null; // Not found
  }
}

// --- AppPath (represents the current navigation state) ---
class AppPath {
  final AppPage mainPage; // Current main tab (Home, Settings, Sandbox)
  final List<String> subPageStack; // Stack of sub-page routes

  AppPath(this.mainPage, [this.subPageStack = const []]);

  bool get hasSubPages => subPageStack.isNotEmpty;
  String? get currentSubPage =>
      subPageStack.isNotEmpty ? subPageStack.last : null;

  static AppPath home = AppPath(AppPage.home);
  static AppPath settings = AppPath(AppPage.settings);
  static AppPath sandbox = AppPath(AppPage.sandbox);

  // Create AppPath from NavState
  factory AppPath.fromNavState(NavState navState) {
    return AppPath(navState.mainPage, navState.subPageStack);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppPath &&
        other.mainPage == mainPage &&
        other.subPageStack.length == subPageStack.length &&
        other.subPageStack.every((element) => subPageStack.contains(element));
  }

  @override
  int get hashCode => Object.hash(mainPage, subPageStack);
}

// --- RouterDelegate ---
class AppRouterDelegate extends RouterDelegate<AppPath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final NavBloc navBloc;

  AppPath _currentPath = AppPath.home;

  AppRouterDelegate(this.navBloc) {
    navBloc.stream.listen((navState) {
      _currentPath = AppPath.fromNavState(navState);
      notifyListeners();
    });
  }

  @override
  AppPath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    List<Page> stack = [];

    // Add the main page (which includes the MainScaffold with BottomNavBar)
    stack.add(
      MainTabPage(
        // Use MainTabPage for custom transition
        key: ValueKey('MainScaffold_${_currentPath.mainPage.name}'),
        name:
            'MainScaffold_${_currentPath.mainPage.name}', // Optional: for route observers/debugging
        child: MainScaffold(
          currentMainPage: _currentPath.mainPage,
          onNavigateToMainPage: (page) {
            // For BottomNavBar taps
            navBloc.add(NavTo(page));
          },
          // Pass a method to allow MainScaffold to push sub-pages
          onPushSubPage: (route) {
            navBloc.add(NavPushSubPage(route));
          },
        ),
      ),
    );

    // Add all sub-pages from the stack
    for (String subPageRoute in _currentPath.subPageStack) {
      final config = navScreenConfigFromRoute(subPageRoute);
      if (config != null) {
        stack.add(
          MaterialPage(
            key: ValueKey(subPageRoute),
            name: subPageRoute,
            child: config.builder(),
          ),
        );
      } else {
        // Handle unknown sub-page route, e.g., show a NotFoundPage
        stack.add(
          const MaterialPage(
            key: ValueKey('NotFoundPage_Sub'),
            child: NotFoundPage(),
          ),
        );
      }
    }

    return Navigator(
      key: navigatorKey,
      pages: stack,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        // If we are on a sub-page, pop it using the BLoC
        if (_currentPath.hasSubPages) {
          navBloc.add(NavPopSubPage());
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppPath path) async {
    // This is called by the RouteInformationParser
    // Update NavBloc to match the new path
    navBloc.add(NavResetToMainPage(path.mainPage));

    // Push all sub-pages in order
    for (String subPageRoute in path.subPageStack) {
      navBloc.add(NavPushSubPage(subPageRoute));
    }
  }

  // Method to navigate to a sub-page from anywhere (e.g., SandboxPage)
  void pushSubPage(String route) {
    navBloc.add(NavPushSubPage(route));
  }

  // Method to navigate to a main page (used by BottomNavBar)
  void navigateToMainPage(AppPage page) {
    navBloc.add(NavTo(page));
  }
}

// --- RouteInformationParser ---
class AppRouteInformationParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = Uri.parse(routeInformation.location);
    if (uri.pathSegments.isEmpty || uri.path == '/') {
      return AppPath.home; // Default to home
    }

    // Try to match a main page route
    final mainPageConfig = navScreenConfigFromRoute('/${uri.pathSegments[0]}');
    if (mainPageConfig != null && mainPageConfig.inNavBar) {
      AppPage mainPage = AppPage.values.firstWhere(
        (p) => routeFromAppPage(p) == mainPageConfig.route,
        orElse: () => AppPage.home,
      );

      if (uri.pathSegments.length > 1) {
        // We have a sub-page
        final fullSubPageRoute =
            (uri.pathSegments.length > 1 &&
                !uri.pathSegments[1].startsWith('/'))
            ? '/' + uri.pathSegments.sublist(1).join('/')
            : uri.pathSegments.sublist(1).join('/');

        final subPageConfig = navScreenConfigFromRoute(fullSubPageRoute);
        if (subPageConfig != null) {
          return AppPath(mainPage, [fullSubPageRoute]);
        } else {
          // Invalid sub-page, go to main page
          print("Could not find sub page config for: $fullSubPageRoute");
          return AppPath(mainPage); // Just the main page
        }
      }
      return AppPath(mainPage); // Just the main page
    }

    // Fallback for unknown routes or direct sub-page links
    final directSubPageConfig = navScreenConfigFromRoute(uri.path);
    if (directSubPageConfig != null && !directSubPageConfig.inNavBar) {
      // If it's a known sub-page, default to sandbox main page with this subpage
      return AppPath(AppPage.sandbox, [uri.path]);
    }

    print("Route not recognized, defaulting to home: ${uri.path}");
    return AppPath.home; // Default to home page
  }

  @override
  RouteInformation? restoreRouteInformation(AppPath path) {
    String location = routeFromAppPage(path.mainPage);
    if (path.hasSubPages) {
      // Add the current sub-page to the location
      if (path.currentSubPage != null && path.currentSubPage!.isNotEmpty) {
        location +=
            (path.currentSubPage!.startsWith('/') ? '' : '/') +
            path.currentSubPage!;
      }
    }
    // Ensure the location always starts with a /
    if (!location.startsWith('/')) {
      location = '/$location';
    }
    // And remove trailing slash if it's not the root
    if (location != '/' && location.endsWith('/')) {
      location = location.substring(0, location.length - 1);
    }
    return RouteInformation(location: location);
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
  final Key _homeKey = const PageStorageKey<String>('homePage');
  final Key _settingsKey = const PageStorageKey<String>('settingsPage');
  final Key _sandboxKey = const PageStorageKey<String>('sandboxPage');

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
          child: HomePage(key: _homeKey),
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
          child: SandboxPage(
            key:
                _sandboxKey /*, onPushSubPage: widget.onPushSubPage (add this later) */,
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
              currentIndex: AppPage.values.indexOf(widget.currentMainPage),
              onTap: (index) {
                widget.onNavigateToMainPage(AppPage.values[index]);
              },
            )
          : null,
    );
  }
}
