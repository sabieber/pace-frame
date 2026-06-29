/// Drift database definition and local SQLite connection.
///
/// Defines the [Activities] table that caches Strava activity summaries.
/// The generated `database.g.dart` (produced by `build_runner`) contains
/// type-safe query code and the `Activity` data class used throughout the
/// app. Schema migrations go into [AppDatabase.schemaVersion].
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Activities extends Table {
  IntColumn get id => integer()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  DateTimeColumn get startDate => dateTime()();

  RealColumn get distance => real()();

  IntColumn get movingTime => integer()();

  RealColumn get averageWatts => real().nullable()();

  RealColumn get averageHeartRate => real().nullable()();

  RealColumn get elevationGain => real().nullable()();

  TextColumn get summaryPolyline => text().nullable()();

  TextColumn get polyline => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Activities])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(activities, activities.polyline);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'paceframe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
