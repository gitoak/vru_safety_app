import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection/service_locator_simple.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/panic/panic_bloc.dart';
import 'presentation/blocs/onboarding/onboarding_bloc.dart';
import 'presentation/blocs/onboarding/onboarding_state.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up dependency injection
  await setupServiceLocator();
  
  runApp(const VRUSafetyApp());
}

class VRUSafetyApp extends StatelessWidget {
  const VRUSafetyApp({super.key});  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => serviceLocator<SettingsBloc>()),
        BlocProvider(create: (context) => serviceLocator<PanicBloc>()),
        BlocProvider(create: (context) => serviceLocator<OnboardingBloc>()),
      ],
      child: MaterialApp(
        title: 'VRU Safety App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state.showOnboarding) {
          return const OnboardingPage();
        } else {
          return const NavigationPage();
        }
      },
    );
  }
}