import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/editor/frame_config_provider.dart';
import 'package:pace_frame/models/aspect_ratio_preset.dart';
import 'package:pace_frame/models/frame_config.dart';

void main() {
  group('FrameConfigNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state has activityId 0', () {
      final config = container.read(frameConfigProvider);
      expect(config.activityId, 0);
    });

    test('initial state has default aspect ratio', () {
      final config = container.read(frameConfigProvider);
      expect(config.aspectRatio, AspectRatioPreset.story9x16);
    });

    test('initial state has empty widgets', () {
      final config = container.read(frameConfigProvider);
      expect(config.widgets, isEmpty);
    });

    test('update replaces the config', () {
      const newConfig = FrameConfig(
        activityId: 42,
        aspectRatio: AspectRatioPreset.post1x1,
        showRoute: false,
      );

      container.read(frameConfigProvider.notifier).update(newConfig);

      final config = container.read(frameConfigProvider);
      expect(config.activityId, 42);
      expect(config.aspectRatio, AspectRatioPreset.post1x1);
      expect(config.showRoute, isFalse);
    });

    test('multiple updates accumulate correctly', () {
      const first = FrameConfig(activityId: 1);
      container.read(frameConfigProvider.notifier).update(first);

      final updated = container.read(frameConfigProvider).copyWith(
        activityId: 2,
        aspectRatio: AspectRatioPreset.post4x5,
      );
      container.read(frameConfigProvider.notifier).update(updated);

      final config = container.read(frameConfigProvider);
      expect(config.activityId, 2);
      expect(config.aspectRatio, AspectRatioPreset.post4x5);
    });

    group('addWidget', () {
      test('adds a widget to the list', () {
        container.read(frameConfigProvider.notifier).addWidget(
          StatBlockType.distance,
        );

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
        expect(config.widgets.first.type, StatBlockType.distance);
      });

      test('new widget has default center position', () {
        container.read(frameConfigProvider.notifier).addWidget(
          StatBlockType.avgPace,
        );

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.5, 0.5));
      });

      test('multiple widgets get unique ids', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.distance);
        notifier.addWidget(StatBlockType.duration);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(2));
        expect(config.widgets[0].id, isNot(config.widgets[1].id));
      });
    });

    group('removeWidget', () {
      test('removes widget by id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.distance);
        notifier.addWidget(StatBlockType.duration);

        final id = container.read(frameConfigProvider).widgets.first.id;
        notifier.removeWidget(id);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
        expect(config.widgets.first.type, StatBlockType.duration);
      });

      test('no-op for unknown id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.distance);
        notifier.removeWidget(99999);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
      });
    });

    group('moveWidget', () {
      test('updates widget position', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.distance);

        final id = container.read(frameConfigProvider).widgets.first.id;
        notifier.moveWidget(id, const Offset(0.2, 0.8));

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.2, 0.8));
      });

      test('preserves widget id and type', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.avgWatts);

        final w = container.read(frameConfigProvider).widgets.first;
        notifier.moveWidget(w.id, const Offset(0.1, 0.9));

        final moved = container.read(frameConfigProvider).widgets.first;
        expect(moved.id, w.id);
        expect(moved.type, StatBlockType.avgWatts);
      });

      test('no-op for unknown id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(StatBlockType.distance);
        notifier.moveWidget(99999, const Offset(0.1, 0.1));

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.5, 0.5));
      });
    });
  });
}
