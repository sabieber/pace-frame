import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Activities table', () {
    test('inserts and retrieves an activity', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(1),
          name: 'Morning Run',
          type: 'Run',
          startDate: DateTime(2025, 6, 20, 8, 0),
          distance: 5230.5,
          movingTime: 1500,
        ),
      );

      final rows = await db.select(db.activities).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 1);
      expect(rows.first.name, 'Morning Run');
      expect(rows.first.type, 'Run');
      expect(rows.first.distance, 5230.5);
      expect(rows.first.movingTime, 1500);
    });

    test('nullable fields default to null', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(2),
          name: 'Evening Ride',
          type: 'Ride',
          startDate: DateTime(2025, 6, 19),
          distance: 30000,
          movingTime: 3600,
        ),
      );

      final row = await (db.select(db.activities)..where((a) => a.id.equals(2)))
          .getSingle();
      expect(row.averageWatts, isNull);
      expect(row.averageHeartRate, isNull);
      expect(row.elevationGain, isNull);
      expect(row.summaryPolyline, isNull);
    });

    test('upsert updates existing activity by id', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(10),
          name: 'Run v1',
          type: 'Run',
          startDate: DateTime(2025, 6, 1),
          distance: 1000,
          movingTime: 300,
        ),
      );

      await db.into(db.activities).insertOnConflictUpdate(
        ActivitiesCompanion.insert(
          id: const Value(10),
          name: 'Run v2',
          type: 'Run',
          startDate: DateTime(2025, 6, 1),
          distance: 5000,
          movingTime: 1500,
        ),
      );

      final rows = await db.select(db.activities).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Run v2');
      expect(rows.first.distance, 5000);
      expect(rows.first.movingTime, 1500);
    });

    test('orderBy descending startDate returns newest first', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(1),
          name: 'Old',
          type: 'Run',
          startDate: DateTime(2025, 1, 1),
          distance: 1000,
          movingTime: 300,
        ),
      );
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(2),
          name: 'New',
          type: 'Run',
          startDate: DateTime(2025, 6, 1),
          distance: 2000,
          movingTime: 600,
        ),
      );

      final query = db.select(db.activities)
        ..orderBy([(a) => OrderingTerm.desc(a.startDate)]);
      final rows = await query.get();

      expect(rows.first.name, 'New');
      expect(rows.last.name, 'Old');
    });

    test('stores nullable numeric fields correctly', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(3),
          name: 'Interval Run',
          type: 'Run',
          startDate: DateTime(2025, 6, 15),
          distance: 8000,
          movingTime: 2400,
          averageWatts: const Value(245.5),
          averageHeartRate: const Value(162.0),
          elevationGain: const Value(120.3),
        ),
      );

      final row = await (db.select(db.activities)..where((a) => a.id.equals(3)))
          .getSingle();
      expect(row.averageWatts, 245.5);
      expect(row.averageHeartRate, 162.0);
      expect(row.elevationGain, 120.3);
    });

    test('watch emits updates on insert', () async {
      final query = db.select(db.activities);
      final emissions = <List<Activity>>[];
      final sub = query.watch().listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(1),
          name: 'Test',
          type: 'Run',
          startDate: DateTime(2025, 6, 1),
          distance: 1000,
          movingTime: 300,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, hasLength(1));

      await sub.cancel();
    });

    test('deletes all activities', () async {
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(1),
          name: 'A',
          type: 'Run',
          startDate: DateTime(2025, 6, 1),
          distance: 1000,
          movingTime: 300,
        ),
      );
      await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          id: const Value(2),
          name: 'B',
          type: 'Ride',
          startDate: DateTime(2025, 6, 2),
          distance: 5000,
          movingTime: 900,
        ),
      );

      await db.delete(db.activities).go();

      final rows = await db.select(db.activities).get();
      expect(rows, isEmpty);
    });
  });
}
