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

    test('update preserves statBlocks from new config', () {
      const newConfig = FrameConfig(
        activityId: 10,
        statBlocks: [
          StatBlock(type: StatBlockType.distance),
          StatBlock(type: StatBlockType.duration, enabled: false),
        ],
      );

      container.read(frameConfigProvider.notifier).update(newConfig);

      final config = container.read(frameConfigProvider);
      expect(config.statBlocks, hasLength(2));
      expect(config.statBlocks[1].enabled, isFalse);
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
  });
}
