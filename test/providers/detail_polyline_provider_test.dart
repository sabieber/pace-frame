import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strava_client/strava_client.dart';

import 'package:pace_frame/data/database.dart';
import 'package:pace_frame/editor/detail_polyline_provider.dart';
import 'package:pace_frame/providers.dart';

class MockStravaClient extends Mock implements StravaClient {}

class MockRepositoryActivity extends Mock implements RepositoryActivity {}

void main() {
  late AppDatabase db;
  late MockStravaClient mockClient;
  late MockRepositoryActivity mockActivities;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockClient = MockStravaClient();
    mockActivities = MockRepositoryActivity();

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

  Future<void> insertActivity({
    required int id,
    String? summaryPolyline,
    String? polyline,
  }) async {
    await db.into(db.activities).insert(
      ActivitiesCompanion.insert(
        id: Value(id),
        name: 'Test',
        type: 'Run',
        startDate: DateTime(2025, 6, 1),
        distance: 1000,
        movingTime: 300,
        summaryPolyline: Value(summaryPolyline),
        polyline: Value(polyline),
      ),
    );
  }

  group('detailPolylineProvider', () {
    test('returns cached polyline if already stored', () async {
      await insertActivity(
        id: 1,
        summaryPolyline: 'summary',
        polyline: 'detail',
      );

      final result = await container.read(
        detailPolylineProvider(1).future,
      );

      expect(result, 'detail');
      verifyNever(() => mockActivities.getActivity(any()));
    });

    test('fetches from API and caches when not stored', () async {
      await insertActivity(id: 1, summaryPolyline: 'summary');

      final detail = DetailedActivity(
        id: 1,
        map: PolyLineMap(polyline: 'detail-from-api'),
      );
      when(() => mockActivities.getActivity(1)).thenAnswer((_) async => detail);

      final result = await container.read(
        detailPolylineProvider(1).future,
      );

      expect(result, 'detail-from-api');
      verify(() => mockActivities.getActivity(1)).called(1);

      final row = await (db.select(db.activities)
            ..where((a) => a.id.equals(1)))
          .getSingle();
      expect(row.polyline, 'detail-from-api');
    });

    test('falls back to summary polyline on API failure', () async {
      await insertActivity(id: 1, summaryPolyline: 'summary');

      when(() => mockActivities.getActivity(1)).thenThrow(Exception('fail'));

      final result = await container.read(
        detailPolylineProvider(1).future,
      );

      expect(result, 'summary');
    });

    test('returns null when activity not found', () async {
      final result = await container.read(
        detailPolylineProvider(999).future,
      );

      expect(result, isNull);
    });

    test('returns summary if API returns null polyline', () async {
      await insertActivity(id: 1, summaryPolyline: 'summary');

      final detail = DetailedActivity(id: 1, map: PolyLineMap());
      when(() => mockActivities.getActivity(1)).thenAnswer((_) async => detail);

      final result = await container.read(
        detailPolylineProvider(1).future,
      );

      expect(result, 'summary');
    });
  });
}
