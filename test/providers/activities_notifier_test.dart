import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strava_client/strava_client.dart';

import 'package:pace_frame/activities/activities_repository.dart';
import 'package:pace_frame/data/database.dart';
import 'package:pace_frame/providers.dart';

class MockStravaClient extends Mock implements StravaClient {}

class MockRepositoryAuthentication extends Mock
    implements RepositoryAuthentication {}

class MockRepositoryActivity extends Mock implements RepositoryActivity {}

void main() {
  late AppDatabase db;
  late MockStravaClient mockClient;
  late MockRepositoryAuthentication mockAuth;
  late MockRepositoryActivity mockActivities;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockClient = MockStravaClient();
    mockAuth = MockRepositoryAuthentication();
    mockActivities = MockRepositoryActivity();

    when(() => mockClient.authentication).thenReturn(mockAuth);
    when(() => mockClient.activities).thenReturn(mockActivities);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        stravaClientProvider.overrideWithValue(mockClient),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async => db.close());
  });

  group('ActivitiesNotifier', () {
    test('initial state is loading', () {
      final state = container.read(activitiesProvider);
      expect(state, isA<AsyncLoading<List<Activity>>>());
    });

    test('syncActivities fetches and stores activities', () async {
      final summaryActivities = [
        SummaryActivity(
          id: 100,
          name: 'Morning Run',
          type: 'Run',
          startDate: '2025-06-20T08:00:00Z',
          distance: 5000,
          movingTime: 1500,
          averageWatts: 200,
          averageHeartrate: 155,
          totalElevationGain: 50,
          map: PolyLineMap(summaryPolyline: 'abc123'),
        ),
        SummaryActivity(
          id: 101,
          name: 'Evening Ride',
          type: 'Ride',
          startDate: '2025-06-19T18:00:00Z',
          distance: 30000,
          movingTime: 3600,
          averageWatts: 180,
          averageHeartrate: 140,
          totalElevationGain: 200,
          map: PolyLineMap(summaryPolyline: 'xyz789'),
        ),
      ];

      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => summaryActivities);

      final notifier = container.read(activitiesProvider.notifier);
      await notifier.syncActivities();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(activitiesProvider);
      expect(state, isA<AsyncData<List<Activity>>>());
      final activities = (state as AsyncData<List<Activity>>).value;
      expect(activities, hasLength(2));

      final rows = await db.select(db.activities).get();
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.name).toSet(), {'Morning Run', 'Evening Ride'});
    });

    test('syncActivities handles empty response', () async {
      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => []);

      final notifier = container.read(activitiesProvider.notifier);
      await notifier.syncActivities();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final rows = await db.select(db.activities).get();
      expect(rows, isEmpty);
    });

    test('syncActivities paginates when page is full', () async {
      final fullPage = List.generate(
        30,
        (i) => SummaryActivity(
          id: i,
          name: 'Activity $i',
          type: 'Run',
          startDate: '2025-06-20T08:00:00Z',
          distance: 1000,
          movingTime: 300,
        ),
      );

      var callCount = 0;
      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return fullPage;
        return [];
      });

      final notifier = container.read(activitiesProvider.notifier);
      await notifier.syncActivities();

      expect(callCount, 2);
    });

    test('syncActivities sets error state on failure', () async {
      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenThrow(Exception('network error'));

      final notifier = container.read(activitiesProvider.notifier);
      await notifier.syncActivities();

      final state = container.read(activitiesProvider);
      expect(state, isA<AsyncError<List<Activity>>>());
    });

    test('syncActivities upserts without duplicates', () async {
      final activity = SummaryActivity(
        id: 1,
        name: 'Run v1',
        type: 'Run',
        startDate: '2025-06-20T08:00:00Z',
        distance: 5000,
        movingTime: 1500,
      );

      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => [activity]);

      final notifier = container.read(activitiesProvider.notifier);
      await notifier.syncActivities();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated = SummaryActivity(
        id: 1,
        name: 'Run v2',
        type: 'Run',
        startDate: '2025-06-20T08:00:00Z',
        distance: 6000,
        movingTime: 1800,
      );

      when(
        () => mockActivities.listLoggedInAthleteActivities(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => [updated]);

      await notifier.syncActivities();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final rows = await db.select(db.activities).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Run v2');
      expect(rows.first.distance, 6000.0);
    });
  });
}
