/// Data models describing a frame's configuration.
///
/// [FrameConfig] is the top-level model persisted in the editor provider:
/// it holds the chosen aspect ratio, background (solid color or image),
/// the list of frame widgets with their positions, and whether the
/// route outline is shown.
library;

import 'dart:ui';

import 'aspect_ratio_preset.dart';

enum BackgroundType { color, image }

class FrameBackground {
  const FrameBackground({
    this.type = BackgroundType.color,
    this.color = const Color(0xFF1A1A2E),
    this.imagePath,
  });

  final BackgroundType type;
  final Color color;
  final String? imagePath;

  FrameBackground copyWith({
    BackgroundType? type,
    Color? color,
    String? imagePath,
  }) {
    return FrameBackground(
      type: type ?? this.type,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

enum StatBlockType { distance, duration, avgPace, avgWatts, avgHr, elevation }

class FrameWidget {
  FrameWidget({required this.type, Offset? position})
    : id = _nextId++,
      position = position ?? const Offset(0.5, 0.5);

  FrameWidget._({required this.id, required this.type, required this.position});

  static int _nextId = 0;

  final int id;
  final StatBlockType type;
  final Offset position;

  FrameWidget copyWith({StatBlockType? type, Offset? position}) {
    return FrameWidget._(
      id: id,
      type: type ?? this.type,
      position: position ?? this.position,
    );
  }
}

class FrameConfig {
  const FrameConfig({
    required this.activityId,
    this.aspectRatio = AspectRatioPreset.story9x16,
    this.background = const FrameBackground(),
    this.widgets = const [],
    this.showRoute = true,
    this.trimEndpoints = true,
  });

  final int activityId;
  final AspectRatioPreset aspectRatio;
  final FrameBackground background;
  final List<FrameWidget> widgets;
  final bool showRoute;
  final bool trimEndpoints;

  FrameConfig copyWith({
    int? activityId,
    AspectRatioPreset? aspectRatio,
    FrameBackground? background,
    List<FrameWidget>? widgets,
    bool? showRoute,
    bool? trimEndpoints,
  }) {
    return FrameConfig(
      activityId: activityId ?? this.activityId,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      background: background ?? this.background,
      widgets: widgets ?? this.widgets,
      showRoute: showRoute ?? this.showRoute,
      trimEndpoints: trimEndpoints ?? this.trimEndpoints,
    );
  }
}
