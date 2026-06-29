import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/models/aspect_ratio_preset.dart';
import 'package:pace_frame/models/frame_config.dart';

void main() {
  group('FrameWidget', () {
    test('assigns unique ids', () {
      final a = FrameWidget(type: StatBlockType.distance);
      final b = FrameWidget(type: StatBlockType.duration);
      expect(a.id, isNot(b.id));
    });

    test('defaults position to center', () {
      final w = FrameWidget(type: StatBlockType.avgPace);
      expect(w.position, const Offset(0.5, 0.5));
    });

    test('accepts custom position', () {
      final w = FrameWidget(
        type: StatBlockType.avgWatts,
        position: const Offset(0.2, 0.8),
      );
      expect(w.position, const Offset(0.2, 0.8));
    });

    test('copyWith overrides position', () {
      final w = FrameWidget(type: StatBlockType.distance);
      final moved = w.copyWith(position: const Offset(0.1, 0.9));
      expect(moved.position, const Offset(0.1, 0.9));
      expect(moved.id, w.id);
      expect(moved.type, w.type);
    });

    test('copyWith overrides type', () {
      final w = FrameWidget(type: StatBlockType.distance);
      final changed = w.copyWith(type: StatBlockType.elevation);
      expect(changed.type, StatBlockType.elevation);
      expect(changed.id, w.id);
    });

    test('copyWith with no args preserves values', () {
      final w = FrameWidget(
        type: StatBlockType.avgHr,
        position: const Offset(0.3, 0.7),
      );
      final copy = w.copyWith();
      expect(copy.id, w.id);
      expect(copy.type, w.type);
      expect(copy.position, w.position);
    });
  });

  group('FrameBackground', () {
    test('defaults to dark color type', () {
      const bg = FrameBackground();
      expect(bg.type, BackgroundType.color);
      expect(bg.color, const Color(0xFF1A1A2E));
      expect(bg.imagePath, isNull);
    });

    test('copyWith overrides color', () {
      const bg = FrameBackground();
      final red = bg.copyWith(color: const Color(0xFFFF0000));
      expect(red.color, const Color(0xFFFF0000));
      expect(red.type, BackgroundType.color);
    });

    test('copyWith overrides type to image', () {
      const bg = FrameBackground();
      final image = bg.copyWith(
        type: BackgroundType.image,
        imagePath: '/tmp/bg.jpg',
      );
      expect(image.type, BackgroundType.image);
      expect(image.imagePath, '/tmp/bg.jpg');
    });

    test('copyWith preserves unspecified fields', () {
      const bg = FrameBackground(
        type: BackgroundType.image,
        color: Color(0xFFAABBCC),
        imagePath: '/some/path.png',
      );
      final copy = bg.copyWith(color: const Color(0xFF112233));
      expect(copy.type, BackgroundType.image);
      expect(copy.imagePath, '/some/path.png');
      expect(copy.color, const Color(0xFF112233));
    });
  });

  group('FrameConfig', () {
    test('defaults are sensible', () {
      const config = FrameConfig(activityId: 42);
      expect(config.activityId, 42);
      expect(config.aspectRatio, AspectRatioPreset.story9x16);
      expect(config.background.type, BackgroundType.color);
      expect(config.widgets, isEmpty);
      expect(config.showRoute, isTrue);
      expect(config.trimEndpoints, isTrue);
    });

    test('copyWith overrides aspectRatio', () {
      const config = FrameConfig(activityId: 1);
      final square = config.copyWith(aspectRatio: AspectRatioPreset.post1x1);
      expect(square.aspectRatio, AspectRatioPreset.post1x1);
      expect(square.activityId, 1);
    });

    test('copyWith overrides showRoute', () {
      const config = FrameConfig(activityId: 1);
      final noRoute = config.copyWith(showRoute: false);
      expect(noRoute.showRoute, isFalse);
    });

    test('copyWith overrides trimEndpoints', () {
      const config = FrameConfig(activityId: 1);
      final noTrim = config.copyWith(trimEndpoints: false);
      expect(noTrim.trimEndpoints, isFalse);
    });

    test('copyWith overrides background', () {
      const config = FrameConfig(activityId: 1);
      final custom = config.copyWith(
        background: const FrameBackground(color: Color(0xFF000000)),
      );
      expect(custom.background.color, const Color(0xFF000000));
    });

    test('copyWith overrides widgets', () {
      const config = FrameConfig(activityId: 1);
      final w = FrameWidget(type: StatBlockType.distance);
      final updated = config.copyWith(widgets: [w]);
      expect(updated.widgets, hasLength(1));
      expect(updated.widgets.first.type, StatBlockType.distance);
    });

    test('copyWith overrides activityId', () {
      const config = FrameConfig(activityId: 1);
      final updated = config.copyWith(activityId: 99);
      expect(updated.activityId, 99);
    });

    test('copyWith with no args returns equivalent config', () {
      final w = FrameWidget(type: StatBlockType.avgPace);
      final config = FrameConfig(
        activityId: 7,
        aspectRatio: AspectRatioPreset.post4x5,
        showRoute: false,
        trimEndpoints: false,
        widgets: [w],
      );
      final copy = config.copyWith();
      expect(copy.activityId, config.activityId);
      expect(copy.aspectRatio, config.aspectRatio);
      expect(copy.showRoute, config.showRoute);
      expect(copy.trimEndpoints, config.trimEndpoints);
      expect(copy.widgets, hasLength(1));
    });
  });
}
