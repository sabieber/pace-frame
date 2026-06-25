/// Core Riverpod providers shared across the app.
///
/// Contains the [AppDatabase] singleton, the [StravaClient] (configured via
/// `--dart-define-from-file=env.json`), and [AuthNotifier] which drives the
/// OAuth login/logout flow. Token persistence and automatic refresh are
/// handled internally by `strava_client`.
///
/// The redirect URL (`paceframe://redirect`) must match the deep-link
/// configuration in `AndroidManifest.xml` and `Info.plist`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strava_client/strava_client.dart';

import 'data/database.dart';

const _stravaClientId = String.fromEnvironment('STRAVA_CLIENT_ID');
const _stravaClientSecret = String.fromEnvironment('STRAVA_CLIENT_SECRET');
const _redirectUrl = 'paceframe://redirect';
const _callbackScheme = 'paceframe';
const _scopes = [
  AuthenticationScope.profile_read_all,
  AuthenticationScope.activity_read_all,
];

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final stravaClientProvider = Provider<StravaClient>((ref) {
  return StravaClient(clientId: _stravaClientId, secret: _stravaClientSecret);
});

class AuthNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _checkAuth();
    return const AsyncValue.loading();
  }

  Future<void> _checkAuth() async {
    try {
      final client = ref.read(stravaClientProvider);
      await client.authentication.authenticate(
        scopes: _scopes,
        redirectUrl: _redirectUrl,
        callbackUrlScheme: _callbackScheme,
      );
      state = const AsyncValue.data(true);
    } catch (_) {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(stravaClientProvider);
      await client.authentication.authenticate(
        scopes: _scopes,
        redirectUrl: _redirectUrl,
        callbackUrlScheme: _callbackScheme,
        forceShowingApproval: true,
      );
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      final client = ref.read(stravaClientProvider);
      await client.authentication.deAuthorize();
    } catch (_) {}
    state = const AsyncValue.data(false);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AsyncValue<bool>>(
  AuthNotifier.new,
);
