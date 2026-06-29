/// Data models describing a frame's configuration.
///
/// [FrameConfig] is the top-level model persisted in the editor provider:
/// it holds the chosen aspect ratio, background (solid color or image),
/// and the list of frame widgets (stat blocks and route) with their
/// positions and settings.
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

enum FrameWidgetType {
  distance,
  duration,
  averagePace,
  averageWatts,
  averageHeartRate,
  elevation,
  route,
}

class FrameWidget {
  FrameWidget({
    required this.type,
    Offset? position,
    this.trimEndpoints = true,
    this.showTitle = true,
    this.showIcon = true,
    this.scale = 1.0,
    this.iconColor = const Color(0xFFFFFFFF),
    this.titleColor = const Color(0xB3FFFFFF),
    this.valueColor = const Color(0xFFFFFFFF),
    this.routeColor = const Color(0xFFFFFFFF),
  }) : id = _nextId++,
        position = position ?? const Offset(0.5, 0.5);

  FrameWidget._({
    required this.id,
    required this.type,
    required this.position,
    required this.trimEndpoints,
    required this.showTitle,
    required this.showIcon,
    required this.scale,
    required this.iconColor,
    required this.titleColor,
    required this.valueColor,
    required this.routeColor,
  });

  static int _nextId = 0;

  final int id;
  final FrameWidgetType type;
  final Offset position;
  final bool trimEndpoints;
  final bool showTitle;
  final bool showIcon;
  final double scale;
  final Color iconColor;
  final Color titleColor;
  final Color valueColor;
  final Color routeColor;

  FrameWidget copyWith({
    FrameWidgetType? type,
    Offset? position,
    bool? trimEndpoints,
    bool? showTitle,
    bool? showIcon,
    double? scale,
    Color? iconColor,
    Color? titleColor,
    Color? valueColor,
    Color? routeColor,
  }) {
    return FrameWidget._(
      id: id,
      type: type ?? this.type,
      position: position ?? this.position,
      trimEndpoints: trimEndpoints ?? this.trimEndpoints,
      showTitle: showTitle ?? this.showTitle,
      showIcon: showIcon ?? this.showIcon,
      scale: scale ?? this.scale,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      valueColor: valueColor ?? this.valueColor,
      routeColor: routeColor ?? this.routeColor,
    );
  }
}

class FrameConfig {
  const FrameConfig({
    required this.activityId,
    this.aspectRatio = AspectRatioPreset.story9x16,
    this.background = const FrameBackground(),
    this.widgets = const [],
  });

  final int activityId;
  final AspectRatioPreset aspectRatio;
  final FrameBackground background;
  final List<FrameWidget> widgets;

  FrameConfig copyWith({
    int? activityId,
    AspectRatioPreset? aspectRatio,
    FrameBackground? background,
    List<FrameWidget>? widgets,
  }) {
    return FrameConfig(
      activityId: activityId ?? this.activityId,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      background: background ?? this.background,
      widgets: widgets ?? this.widgets,
    );
  }
}
