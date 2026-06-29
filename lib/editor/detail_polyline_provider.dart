/// Fetches the detail polyline for an activity from the Strava API.
///
/// Returns the high-resolution polyline, falling back to the cached summary
/// polyline if the API call fails. Caches the detail polyline in the local
/// database so subsequent lookups avoid an extra API call.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';

final detailPolylineProvider = FutureProvider.autoDispose
    .family<String?, int>((ref, activityId) async {
  final db = ref.read(databaseProvider);

  final row = await (db.select(db.activities)
        ..where((a) => a.id.equals(activityId)))
      .getSingleOrNull();

  if (row == null) return null;
  if (row.polyline != null) return row.polyline;

  final summary = row.summaryPolyline;

  try {
    final client = ref.read(stravaClientProvider);
    final detail = await client.activities.getActivity(activityId);
    final polyline = detail.map?.polyline;

    if (polyline != null) {
      await (db.update(db.activities)
            ..where((a) => a.id.equals(activityId)))
          .write(ActivitiesCompanion(polyline: Value(polyline)));
      return polyline;
    }
  } catch (_) {}

  return summary;
});
