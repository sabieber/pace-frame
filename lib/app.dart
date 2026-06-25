/// Root MaterialApp widget.
///
/// Sets up theming (Strava-orange seed, Material 3, light + dark) and gates
/// the app on authentication state: shows a splash while the stored token
/// is validated, the login screen when unauthenticated, and the activity
/// list when authenticated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activities/activity_list_screen.dart';
import 'auth/login_screen.dart';
import 'providers.dart';

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
          seedColor: const Color(0xFFFC4C02),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC4C02),
          brightness: Brightness.dark,
        ),
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bike, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
