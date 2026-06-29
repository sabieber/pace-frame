import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/models/aspect_ratio_preset.dart';
import 'package:pace_frame/models/frame_config.dart';

void main() {
  group('FrameWidget', () {
    test('assigns unique ids', () {
      final first = FrameWidget(type: FrameWidgetType.distance);
      final second = FrameWidget(type: FrameWidgetType.duration);
      expect(first.id, isNot(second.id));
    });

    test('defaults position to center', () {
      final paceWidget = FrameWidget(type: FrameWidgetType.averagePace);
      expect(paceWidget.position, const Offset(0.5, 0.5));
    });

    test('defaults trimEndpoints to true', () {
      final widget = FrameWidget(type: FrameWidgetType.route);
      expect(widget.trimEndpoints, isTrue);
    });

    test('accepts custom position', () {
      final wattsWidget = FrameWidget(
        type: FrameWidgetType.averageWatts,
        position: const Offset(0.2, 0.8),
      );
      expect(wattsWidget.position, const Offset(0.2, 0.8));
    });

    test('copyWith overrides position', () {
      final distanceWidget = FrameWidget(type: FrameWidgetType.distance);
      final moved = distanceWidget.copyWith(position: const Offset(0.1, 0.9));
      expect(moved.position, const Offset(0.1, 0.9));
      expect(moved.id, distanceWidget.id);
      expect(moved.type, distanceWidget.type);
    });

    test('copyWith overrides type', () {
      final distanceWidget = FrameWidget(type: FrameWidgetType.distance);
      final changed = distanceWidget.copyWith(type: FrameWidgetType.elevation);
      expect(changed.type, FrameWidgetType.elevation);
      expect(changed.id, distanceWidget.id);
    });

    test('copyWith overrides trimEndpoints', () {
      final widget = FrameWidget(type: FrameWidgetType.route);
      final noTrim = widget.copyWith(trimEndpoints: false);
      expect(noTrim.trimEndpoints, isFalse);
      expect(noTrim.id, widget.id);
    });

    test('copyWith with no args preserves values', () {
      final hrWidget = FrameWidget(
        type: FrameWidgetType.averageHeartRate,
        position: const Offset(0.3, 0.7),
      );
      final copy = hrWidget.copyWith();
      expect(copy.id, hrWidget.id);
      expect(copy.type, hrWidget.type);
      expect(copy.position, hrWidget.position);
      expect(copy.trimEndpoints, hrWidget.trimEndpoints);
    });

    test('defaults colors to white variants', () {
      final widget = FrameWidget(type: FrameWidgetType.distance);
      expect(widget.iconColor, const Color(0xFFFFFFFF));
      expect(widget.titleColor, const Color(0xB3FFFFFF));
      expect(widget.valueColor, const Color(0xFFFFFFFF));
      expect(widget.routeColor, const Color(0xFFFFFFFF));
    });

    test('copyWith overrides iconColor', () {
      final widget = FrameWidget(type: FrameWidgetType.distance);
      final updated = widget.copyWith(iconColor: const Color(0xFFFF0000));
      expect(updated.iconColor, const Color(0xFFFF0000));
      expect(updated.id, widget.id);
      expect(updated.valueColor, widget.valueColor);
    });

    test('copyWith overrides titleColor', () {
      final widget = FrameWidget(type: FrameWidgetType.distance);
      final updated = widget.copyWith(titleColor: const Color(0xFF00FF00));
      expect(updated.titleColor, const Color(0xFF00FF00));
      expect(updated.id, widget.id);
    });

    test('copyWith overrides valueColor', () {
      final widget = FrameWidget(type: FrameWidgetType.distance);
      final updated = widget.copyWith(valueColor: const Color(0xFF0000FF));
      expect(updated.valueColor, const Color(0xFF0000FF));
      expect(updated.id, widget.id);
    });

    test('copyWith overrides routeColor', () {
      final widget = FrameWidget(type: FrameWidgetType.route);
      final updated = widget.copyWith(routeColor: const Color(0xFFFF00FF));
      expect(updated.routeColor, const Color(0xFFFF00FF));
      expect(updated.id, widget.id);
    });

    test('copyWith overrides all colors at once', () {
      final widget = FrameWidget(type: FrameWidgetType.distance);
      final updated = widget.copyWith(
        iconColor: const Color(0xFF111111),
        titleColor: const Color(0xFF222222),
        valueColor: const Color(0xFF333333),
        routeColor: const Color(0xFF444444),
      );
      expect(updated.iconColor, const Color(0xFF111111));
      expect(updated.titleColor, const Color(0xFF222222));
      expect(updated.valueColor, const Color(0xFF333333));
      expect(updated.routeColor, const Color(0xFF444444));
    });

    test('copyWith preserves unspecified colors', () {
      final widget = FrameWidget(
        type: FrameWidgetType.distance,
        iconColor: const Color(0xFFAAAAAA),
        titleColor: const Color(0xFFBBBBBB),
        valueColor: const Color(0xFFCCCCCC),
        routeColor: const Color(0xFFDDDDDD),
      );
      final copy = widget.copyWith(position: const Offset(0.1, 0.2));
      expect(copy.iconColor, const Color(0xFFAAAAAA));
      expect(copy.titleColor, const Color(0xFFBBBBBB));
      expect(copy.valueColor, const Color(0xFFCCCCCC));
      expect(copy.routeColor, const Color(0xFFDDDDDD));
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
    });

    test('copyWith overrides aspectRatio', () {
      const config = FrameConfig(activityId: 1);
      final square = config.copyWith(aspectRatio: AspectRatioPreset.post1x1);
      expect(square.aspectRatio, AspectRatioPreset.post1x1);
      expect(square.activityId, 1);
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
      final distanceWidget = FrameWidget(type: FrameWidgetType.distance);
      final updated = config.copyWith(widgets: [distanceWidget]);
      expect(updated.widgets, hasLength(1));
      expect(updated.widgets.first.type, FrameWidgetType.distance);
    });

    test('copyWith overrides activityId', () {
      const config = FrameConfig(activityId: 1);
      final updated = config.copyWith(activityId: 99);
      expect(updated.activityId, 99);
    });

    test('copyWith with no args returns equivalent config', () {
      final paceWidget = FrameWidget(type: FrameWidgetType.averagePace);
      final config = FrameConfig(
        activityId: 7,
        aspectRatio: AspectRatioPreset.post4x5,
        widgets: [paceWidget],
      );
      final copy = config.copyWith();
      expect(copy.activityId, config.activityId);
      expect(copy.aspectRatio, config.aspectRatio);
      expect(copy.widgets, hasLength(1));
    });
  });
}
