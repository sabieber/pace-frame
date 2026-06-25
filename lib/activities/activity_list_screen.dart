/// Activity list screen — the main screen after login.
///
/// Displays cached activities in a pull-to-refresh list with a manual sync
/// FAB. Each tile shows sport icon, name, date, distance, and duration.
/// Tapping a tile navigates to the frame editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../activities/activities_repository.dart';
import '../data/database.dart';
import '../editor/frame_editor_screen.dart';
import '../providers.dart';

class ActivityListScreen extends ConsumerStatefulWidget {
  const ActivityListScreen({super.key});

  @override
  ConsumerState<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends ConsumerState<ActivityListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activitiesProvider.notifier).syncActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activitiesState = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(activitiesProvider.notifier).syncActivities(),
        child: activitiesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            error: e,
            onRetry: () =>
                ref.read(activitiesProvider.notifier).syncActivities(),
          ),
          data: (activities) => _buildActivityList(activities),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(activitiesProvider.notifier).syncActivities(),
        icon: const Icon(Icons.sync),
        label: const Text('Sync'),
      ),
    );
  }

  Widget _buildActivityList(List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No activities found.\nPull to refresh.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _ActivityTile(activity: activities[index]);
      },
    );
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final distanceKm = (activity.distance / 1000).toStringAsFixed(1);
    final duration = _formatDuration(activity.movingTime);
    final date = DateFormat.yMMMd().format(activity.startDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _activityIcon(activity.type),
        title: Text(activity.name),
        subtitle: Text('$date • $distanceKm km • $duration'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openEditor(context, activity),
      ),
    );
  }

  Widget _activityIcon(String type) {
    final icon = switch (type.toLowerCase()) {
      'run' || 'trailrun' || 'virtualrun' => Icons.directions_run,
      'ride' || 'virtualride' || 'mountainbikeride' => Icons.directions_bike,
      'swim' => Icons.pool,
      'walk' || 'hike' => Icons.hiking,
      'alpineski' || 'nordicski' => Icons.downhill_skiing,
      _ => Icons.fitness_center,
    };
    return CircleAvatar(child: Icon(icon));
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m ${s}s';
  }

  void _openEditor(BuildContext context, Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FrameEditorScreen(activity: activity)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
