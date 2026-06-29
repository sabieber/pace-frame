import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/editor/recent_colors_provider.dart';

void main() {
  group('RecentColorsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is empty', () {
      final colors = container.read(recentColorsProvider);
      expect(colors, isEmpty);
    });

    test('addColor adds a color', () {
      container.read(recentColorsProvider.notifier).addColor(
        const Color(0xFFFF0000),
      );

      final colors = container.read(recentColorsProvider);
      expect(colors, hasLength(1));
      expect(colors.first, const Color(0xFFFF0000));
    });

    test('addColor prepends new color to front', () {
      final notifier = container.read(recentColorsProvider.notifier);
      notifier.addColor(const Color(0xFFFF0000));
      notifier.addColor(const Color(0xFF00FF00));

      final colors = container.read(recentColorsProvider);
      expect(colors, hasLength(2));
      expect(colors[0], const Color(0xFF00FF00));
      expect(colors[1], const Color(0xFFFF0000));
    });

    test('addColor moves duplicate to front', () {
      final notifier = container.read(recentColorsProvider.notifier);
      notifier.addColor(const Color(0xFFFF0000));
      notifier.addColor(const Color(0xFF00FF00));
      notifier.addColor(const Color(0xFFFF0000));

      final colors = container.read(recentColorsProvider);
      expect(colors, hasLength(2));
      expect(colors[0], const Color(0xFFFF0000));
      expect(colors[1], const Color(0xFF00FF00));
    });

    test('addColor caps at 10 colors', () {
      final notifier = container.read(recentColorsProvider.notifier);
      for (var index = 0; index < 15; index++) {
        notifier.addColor(Color(0xFF000000 + index));
      }

      final colors = container.read(recentColorsProvider);
      expect(colors, hasLength(10));
      expect(colors.first, const Color(0xFF00000E));
    });
  });
}
