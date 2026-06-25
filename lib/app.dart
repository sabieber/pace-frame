/// Root MaterialApp widget.
///
/// Sets up theming (brand blue seed, Material 3, light + dark) and gates
/// the app on authentication state: shows a splash while the stored token
/// is validated, the login screen when unauthenticated, and the activity
/// list when authenticated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activities/activity_list_screen.dart';
import 'auth/login_screen.dart';
import 'providers.dart';

const _brandBlue = Color(0xFF0758B8);
const _brandRed = Color(0xFFF44405);

class PaceFrameApp extends ConsumerWidget {
  const PaceFrameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'PaceFrame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandBlue,
          brightness: Brightness.light,
        ).copyWith(secondary: _brandRed, tertiary: _brandRed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandBlue,
          brightness: Brightness.dark,
        ).copyWith(secondary: _brandRed, tertiary: _brandRed),
        useMaterial3: true,
      ),
      home: authState.when(
        loading: () => const _SplashScreen(),
        error: (_, _) => const LoginScreen(),
        data: (isLoggedIn) =>
            isLoggedIn ? const ActivityListScreen() : const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bike,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
