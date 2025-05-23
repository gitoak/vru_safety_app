import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/nav_bloc.dart';
import 'bloc/settings_bloc.dart';
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
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return child;
      },
      transitionDuration: const Duration(milliseconds: 200), // Adjust duration as needed
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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
        home: OnboardingPage(onFinish: _handleOnboardingFinish),
      );
    }

    return MaterialApp.router(
      theme: appTheme,
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
  final String? subPageRoute; // Path of a sub-page, if any

  AppPath(this.mainPage, [this.subPageRoute]);

  bool get isSubPage => subPageRoute != null;

  static AppPath home = AppPath(AppPage.home);
  static AppPath settings = AppPath(AppPage.settings);
  static AppPath sandbox = AppPath(AppPage.sandbox);
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
      // Only update if the main page changes and no sub-page is active
      if (!currentConfiguration.isSubPage && currentConfiguration.mainPage != navState.page) {
        _currentPath = AppPath(navState.page);
        notifyListeners();
      }
    });
  }

  @override
  AppPath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    List<Page> stack = [];

    // Add the main page (which includes the MainScaffold with BottomNavBar)
    stack.add(
      MainTabPage( // Use MainTabPage for custom transition
        key: ValueKey('MainScaffold_${_currentPath.mainPage.name}'),
        name: 'MainScaffold_${_currentPath.mainPage.name}', // Optional: for route observers/debugging
        child: MainScaffold(
          currentMainPage: _currentPath.mainPage,
          onNavigateToMainPage: (page) { // For BottomNavBar taps
            navBloc.add(NavTo(page));
            _currentPath = AppPath(page);
            notifyListeners();
          },
          // Pass a method to allow MainScaffold to push sub-pages
          onPushSubPage: (route) {
            _currentPath = AppPath(_currentPath.mainPage, route);
            notifyListeners();
          },
        ),
      ),
    );

    // If there's a sub-page, add it to the stack
    if (_currentPath.isSubPage) {
      final config = navScreenConfigFromRoute(_currentPath.subPageRoute);
      if (config != null) {
        stack.add(
          MaterialPage(
            key: ValueKey(_currentPath.subPageRoute),
            name: _currentPath.subPageRoute,
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
        // If we are on a sub-page, popping should take us back to the main page
        if (_currentPath.isSubPage) {
          _currentPath = AppPath(_currentPath.mainPage); // Go back to the main page
          notifyListeners();
        }
        // If we are on a main page, popping might exit the app or be handled by RootBackButtonDispatcher
        // For now, let the default behavior handle it.
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppPath path) async {
    // This is called by the RouteInformationParser
    // Update NavBloc if the main page part of the path changes
    if (path.mainPage != navBloc.state.page) {
      navBloc.add(NavTo(path.mainPage));
    }
    _currentPath = path;
    // No need to call notifyListeners() here as it's handled by the system
    // when setNewRoutePath is called.
  }

  // Method to navigate to a sub-page from anywhere (e.g., SandboxPage)
  void pushSubPage(String route) {
    _currentPath = AppPath(currentConfiguration.mainPage, route);
    notifyListeners();
  }

  // Method to navigate to a main page (used by BottomNavBar)
  void navigateToMainPage(AppPage page) {
    navBloc.add(NavTo(page));
    _currentPath = AppPath(page);
    notifyListeners();
  }
}

// --- RouteInformationParser ---
class AppRouteInformationParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location); // Removed ?? '/' as location is non-nullable
    if (uri.pathSegments.isEmpty || uri.path == '/') {
      return AppPath.home; // Default to home
    }

    // Try to match a main page route
    final mainPageConfig = navScreenConfigFromRoute('/${uri.pathSegments[0]}');
    if (mainPageConfig != null && mainPageConfig.inNavBar) {
      AppPage mainPage = AppPage.values.firstWhere(
          (p) => routeFromAppPage(p) == mainPageConfig.route,
          orElse: () => AppPage.home);

      if (uri.pathSegments.length > 1) {
        // We have a sub-page
        // String subPageRoute = '/${uri.pathSegments.sublist(1).join('/')}'; // Unused variable removed
        // We need to ensure the sub-page route is prefixed correctly if it's not absolute
        final fullSubPageRoute = (uri.pathSegments.length > 1 && !uri.pathSegments[1].startsWith('/'))
            ? '/' + uri.pathSegments.sublist(1).join('/')
            : uri.pathSegments.sublist(1).join('/');


        final subPageConfig = navScreenConfigFromRoute(fullSubPageRoute);
        if (subPageConfig != null) {
          return AppPath(mainPage, fullSubPageRoute);
        } else {
           // Invalid sub-page, go to main page or a 404 for the sub-page
          print("Could not find sub page config for: $fullSubPageRoute");
          return AppPath(mainPage, '/404'); // Or just AppPath(mainPage)
        }
      }
      return AppPath(mainPage); // Just the main page
    }

    // Fallback for unknown routes or direct sub-page links (might need more robust handling)
    // For now, try to see if it's a known non-navbar route directly
    final directSubPageConfig = navScreenConfigFromRoute(uri.path);
    if (directSubPageConfig != null && !directSubPageConfig.inNavBar) {
        // If it's a known sub-page, decide a default main page (e.g. home or sandbox)
        // This case is tricky for deep linking directly to subpages without a main page context.
        // For now, let's assume sub-pages are always under a main page context set by _currentPath.
        // So, if a URL like /osm-poc is hit directly, we might default to Sandbox/osm-poc
        // Or, more simply, treat it as a request for that subpage under the *current* main page.
        // This part depends on desired deep-linking behavior.
        // For now, let's assume we default to home and then the subpage.
        return AppPath(AppPage.home, uri.path);
    }


    print("Route not recognized, defaulting to home: ${uri.path}");
    return AppPath(AppPage.home, '/404'); // Or AppPath.home to show main home page
  }

  @override
  RouteInformation? restoreRouteInformation(AppPath path) {
    String location = routeFromAppPage(path.mainPage);
    if (path.isSubPage) {
      // Ensure subPageRoute starts with a slash if it's not empty
      if (path.subPageRoute != null && path.subPageRoute!.isNotEmpty) {
        location += (path.subPageRoute!.startsWith('/') ? '' : '/') + path.subPageRoute!;
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
    orElse: () => navScreens[page.index], // This assumes AppPage enum order matches navScreens order for main pages
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
    final mainPageConfig = navScreenConfigFromRoute(routeFromAppPage(widget.currentMainPage));
    bool showBottomNavBar = mainPageConfig?.inNavBar ?? false;

    // Determine the current body widget based on currentMainPage
    // We wrap each main page view in PageStorage to preserve state
    Widget currentPageWidget;
    switch (widget.currentMainPage) {
      case AppPage.home:
        currentPageWidget = PageStorage(bucket: _bucket, child: HomePage(key: _homeKey));
        break;
      case AppPage.settings:
        currentPageWidget = PageStorage(bucket: _bucket, child: SettingsPage(key: _settingsKey));
        break;
      case AppPage.sandbox:
        // For SandboxPage, we need to pass the onPushSubPage callback
        // This requires modifying SandboxPage to accept this callback.
        currentPageWidget = PageStorage(bucket: _bucket, child: SandboxPage(key: _sandboxKey /*, onPushSubPage: widget.onPushSubPage (add this later) */));
        break;
    }


    return Scaffold(
      // AppBar might be part of individual pages or a common one here
      // For now, let individual pages (including sub-pages) define their own AppBars
      body: currentPageWidget,
      bottomNavigationBar: showBottomNavBar
          ? BottomNavigationBar(
              items: navScreens
                  .where((s) => s.inNavBar)
                  .map((s) => BottomNavigationBarItem(
                        icon: Icon(s.icon),
                        label: s.label,
                      ))
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
