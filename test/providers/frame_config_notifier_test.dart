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
      );

      container.read(frameConfigProvider.notifier).update(newConfig);

      final config = container.read(frameConfigProvider);
      expect(config.activityId, 42);
      expect(config.aspectRatio, AspectRatioPreset.post1x1);
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
          FrameWidgetType.distance,
        );

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
        expect(config.widgets.first.type, FrameWidgetType.distance);
      });

      test('new widget has default center position', () {
        container.read(frameConfigProvider.notifier).addWidget(
          FrameWidgetType.averagePace,
        );

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.5, 0.5));
      });

      test('multiple widgets get unique ids', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);
        notifier.addWidget(FrameWidgetType.duration);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(2));
        expect(config.widgets[0].id, isNot(config.widgets[1].id));
      });

      test('new route widget has trimEndpoints true', () {
        container.read(frameConfigProvider.notifier).addWidget(
          FrameWidgetType.route,
        );

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.type, FrameWidgetType.route);
        expect(config.widgets.first.trimEndpoints, isTrue);
      });
    });

    group('removeWidget', () {
      test('removes widget by id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);
        notifier.addWidget(FrameWidgetType.duration);

        final id = container.read(frameConfigProvider).widgets.first.id;
        notifier.removeWidget(id);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
        expect(config.widgets.first.type, FrameWidgetType.duration);
      });

      test('no-op for unknown id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);
        notifier.removeWidget(99999);

        final config = container.read(frameConfigProvider);
        expect(config.widgets, hasLength(1));
      });
    });

    group('moveWidget', () {
      test('updates widget position', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);

        final id = container.read(frameConfigProvider).widgets.first.id;
        notifier.moveWidget(id, const Offset(0.2, 0.8));

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.2, 0.8));
      });

      test('preserves widget id and type', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.averageWatts);

        final original = container.read(frameConfigProvider).widgets.first;
        notifier.moveWidget(original.id, const Offset(0.1, 0.9));

        final moved = container.read(frameConfigProvider).widgets.first;
        expect(moved.id, original.id);
        expect(moved.type, FrameWidgetType.averageWatts);
      });

      test('no-op for unknown id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);
        notifier.moveWidget(99999, const Offset(0.1, 0.1));

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.position, const Offset(0.5, 0.5));
      });
    });

    group('updateWidget', () {
      test('replaces widget with updated copy', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.route);

        final original = container.read(frameConfigProvider).widgets.first;
        final updated = original.copyWith(trimEndpoints: false);
        notifier.updateWidget(original.id, updated);

        final config = container.read(frameConfigProvider);
        final result = config.widgets.first;
        expect(result.id, original.id);
        expect(result.trimEndpoints, isFalse);
      });

      test('no-op for unknown id', () {
        final notifier = container.read(frameConfigProvider.notifier);
        notifier.addWidget(FrameWidgetType.distance);

        final original = container.read(frameConfigProvider).widgets.first;
        final updated = original.copyWith(trimEndpoints: false);
        notifier.updateWidget(99999, updated);

        final config = container.read(frameConfigProvider);
        expect(config.widgets.first.trimEndpoints, isTrue);
      });
    });
  });
}
