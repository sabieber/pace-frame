/// Data models describing a frame's configuration.
///
/// [FrameConfig] is the top-level model persisted in the editor provider:
/// it holds the chosen aspect ratio, background (solid color or image),
/// the list of stat blocks with their enabled state, and whether the
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

class StatBlock {
  const StatBlock({required this.type, this.enabled = true});

  final StatBlockType type;
  final bool enabled;

  StatBlock copyWith({StatBlockType? type, bool? enabled}) {
    return StatBlock(type: type ?? this.type, enabled: enabled ?? this.enabled);
  }
}

class FrameConfig {
  const FrameConfig({
    required this.activityId,
    this.aspectRatio = AspectRatioPreset.story9x16,
    this.background = const FrameBackground(),
    this.statBlocks = const [
      StatBlock(type: StatBlockType.distance),
      StatBlock(type: StatBlockType.duration),
      StatBlock(type: StatBlockType.avgPace),
      StatBlock(type: StatBlockType.avgWatts),
      StatBlock(type: StatBlockType.avgHr),
      StatBlock(type: StatBlockType.elevation),
    ],
    this.showRoute = true,
    this.trimEndpoints = true,
  });

  final int activityId;
  final AspectRatioPreset aspectRatio;
  final FrameBackground background;
  final List<StatBlock> statBlocks;
  final bool showRoute;
  final bool trimEndpoints;

  FrameConfig copyWith({
    int? activityId,
    AspectRatioPreset? aspectRatio,
    FrameBackground? background,
    List<StatBlock>? statBlocks,
    bool? showRoute,
    bool? trimEndpoints,
  }) {
    return FrameConfig(
      activityId: activityId ?? this.activityId,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      background: background ?? this.background,
      statBlocks: statBlocks ?? this.statBlocks,
      showRoute: showRoute ?? this.showRoute,
      trimEndpoints: trimEndpoints ?? this.trimEndpoints,
    );
  }
}
