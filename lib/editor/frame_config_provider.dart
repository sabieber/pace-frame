/// Riverpod provider for the current [FrameConfig] in the editor.
///
/// The editor initialises the config in a post-frame callback after
/// navigating from the activity list, then mutations go through
/// [FrameConfigNotifier.update].
library;

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frame_config.dart';

class FrameConfigNotifier extends Notifier<FrameConfig> {
  @override
  FrameConfig build() => const FrameConfig(activityId: 0);

  void update(FrameConfig config) {
    state = config;
  }

  void addWidget(FrameWidgetType type) {
    final widget = FrameWidget(type: type);
    state = state.copyWith(widgets: [...state.widgets, widget]);
  }

  void removeWidget(int id) {
    state = state.copyWith(
      widgets: state.widgets.where((widget) => widget.id != id).toList(),
    );
  }

  void moveWidget(int id, Offset position) {
    state = state.copyWith(
      widgets: [
        for (final widget in state.widgets)
          if (widget.id == id) widget.copyWith(position: position) else widget,
      ],
    );
  }

  void updateWidget(int id, FrameWidget updated) {
    state = state.copyWith(
      widgets: [
        for (final widget in state.widgets)
          if (widget.id == id) updated else widget,
      ],
    );
  }

  void scaleWidget(int id, double scale) {
    state = state.copyWith(
      widgets: [
        for (final widget in state.widgets)
          if (widget.id == id) widget.copyWith(scale: scale) else widget,
      ],
    );
  }

  /// Updates a widget's [scale] and top-left [position] together so a
  /// center-anchored resize commits in a single rebuild.
  void resizeWidget(int id, double scale, Offset position) {
    state = state.copyWith(
      widgets: [
        for (final widget in state.widgets)
          if (widget.id == id)
            widget.copyWith(scale: scale, position: position)
          else
            widget,
      ],
    );
  }
}

final frameConfigProvider = NotifierProvider<FrameConfigNotifier, FrameConfig>(
  FrameConfigNotifier.new,
);
