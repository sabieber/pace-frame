/// Syncs Strava activities into the local drift database.
///
/// [ActivitiesNotifier] watches the `activities` table reactively and exposes
/// a `syncActivities()` method that paginates the last 90 days from the
/// Strava API, upserting each [SummaryActivity] into SQLite. Strava rate
/// limits (~100 req/15 min) are respected by caching aggressively and only
/// re-fetching on explicit sync or pull-to-refresh.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strava_client/strava_client.dart';

import '../data/database.dart';
import '../providers.dart';

class ActivitiesNotifier extends Notifier<AsyncValue<List<Activity>>> {
  StreamSubscription<List<Activity>>? _sub;

  @override
  AsyncValue<List<Activity>> build() {
    _watch();
    ref.onDispose(() => _sub?.cancel());
    return const AsyncValue.loading();
  }

  void _watch() {
    final db = ref.read(databaseProvider);
    final query = db.select(db.activities)
      ..orderBy([(a) => OrderingTerm.desc(a.startDate)]);
    _sub = query.watch().listen((rows) {
      state = AsyncValue.data(rows);
    });
  }

  Future<void> syncActivities() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(stravaClientProvider);
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final after = now.subtract(const Duration(days: 90));

      final activities = <SummaryActivity>[];
      var page = 1;
      while (true) {
        final batch = await client.activities.listLoggedInAthleteActivities(
          now,
          after,
          page,
          30,
        );
        activities.addAll(batch);
        if (batch.length < 30) break;
        page++;
      }

      await db.transaction(() async {
        for (final activity in activities) {
          await db
              .into(db.activities)
              .insertOnConflictUpdate(
                ActivitiesCompanion(
                  id: Value(activity.id ?? 0),
                  name: Value(activity.name ?? ''),
                  type: Value(activity.type ?? ''),
                  startDate: Value(
                    activity.startDate != null
                        ? DateTime.parse(activity.startDate!)
                        : DateTime.now(),
                  ),
                  distance: Value((activity.distance ?? 0).toDouble()),
                  movingTime: Value(activity.movingTime ?? 0),
                  avgWatts: Value(activity.averageWatts?.toDouble()),
                  avgHeartrate: Value(activity.averageHeartrate?.toDouble()),
                  elevationGain: Value(activity.totalElevationGain?.toDouble()),
                  summaryPolyline: Value(activity.map?.summaryPolyline),
                ),
              );
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activitiesProvider =
    NotifierProvider<ActivitiesNotifier, AsyncValue<List<Activity>>>(
      ActivitiesNotifier.new,
    );
