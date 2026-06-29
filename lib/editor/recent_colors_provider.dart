import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kMaxRecentColors = 10;

class RecentColorsNotifier extends Notifier<List<Color>> {
  @override
  List<Color> build() => [];

  void addColor(Color color) {
    final updated = [color, ...state.where((existing) => existing != color)];
    state = updated.take(_kMaxRecentColors).toList();
  }
}

final recentColorsProvider =
    NotifierProvider<RecentColorsNotifier, List<Color>>(
      RecentColorsNotifier.new,
    );
