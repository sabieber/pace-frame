import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strava_client/strava_client.dart';

import 'package:pace_frame/providers.dart';

class MockStravaClient extends Mock implements StravaClient {}

class MockRepositoryAuthentication extends Mock
    implements RepositoryAuthentication {}

void main() {
  late MockStravaClient mockClient;
  late MockRepositoryAuthentication mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockStravaClient();
    mockAuth = MockRepositoryAuthentication();
    when(() => mockClient.authentication).thenReturn(mockAuth);

    container = ProviderContainer(
      overrides: [
        stravaClientProvider.overrideWithValue(mockClient),
      ],
    );
    addTearDown(container.dispose);
  });

  group('AuthNotifier', () {
    test('build sets data(true) when already authenticated', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      container.read(authStateProvider.notifier);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isTrue);
    });

    test('build sets data(false) when not authenticated', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => throw Exception('not authenticated'));

      container.read(authStateProvider.notifier);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isFalse);
    });

    test('login sets data(true) on success', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
          forceShowingApproval: any(named: 'forceShowingApproval'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      container.read(authStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authStateProvider.notifier).login();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isTrue);
    });

    test('login sets error on failure', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenThrow(Exception('initial fail'));

      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
          forceShowingApproval: any(named: 'forceShowingApproval'),
        ),
      ).thenAnswer((_) async => throw Exception('login fail'));

      container.read(authStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authStateProvider.notifier).login();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncError<bool>>());
    });

    test('logout sets data(false)', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      when(() => mockAuth.deAuthorize()).thenAnswer((_) async {});

      container.read(authStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isFalse);
    });

    test('logout calls deAuthorize', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      when(() => mockAuth.deAuthorize()).thenAnswer((_) async {});

      container.read(authStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authStateProvider.notifier).logout();

      verify(() => mockAuth.deAuthorize()).called(1);
    });

    test('logout sets data(false) even if deAuthorize throws', () async {
      when(
        () => mockAuth.authenticate(
          scopes: any(named: 'scopes'),
          redirectUrl: any(named: 'redirectUrl'),
          callbackUrlScheme: any(named: 'callbackUrlScheme'),
        ),
      ).thenAnswer((_) async => TokenResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: 0,
        expiresIn: 0,
        tokenType: 'Bearer',
      ));

      when(() => mockAuth.deAuthorize()).thenThrow(Exception('deauth fail'));

      container.read(authStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<bool>>());
      expect((state as AsyncData<bool>).value, isFalse);
    });
  });
}
