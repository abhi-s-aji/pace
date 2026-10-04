import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/pace_theme.dart';
import 'core/state/pace_providers.dart';
import 'app/app_shell.dart';
import 'features/onboarding/onboarding_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PaceApp(),
    ),
  );
}

class PaceApp extends ConsumerWidget {
  const PaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paceAppProvider);

    if (state.isLoading) {
      return MaterialApp(
        title: 'Pace',
        debugShowCheckedModeBanner: false,
        theme: PaceTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final hasCompletedOnboarding = state.preferences.hasCompletedOnboarding;

    return MaterialApp(
      title: 'Pace',
      debugShowCheckedModeBanner: false,
      theme: PaceTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: hasCompletedOnboarding
          ? const AppShell()
          : const OnboardingPage(),
    );
  }
}
