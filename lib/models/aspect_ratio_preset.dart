/// Fixed aspect-ratio presets for the frame editor.
///
/// Each preset defines a width/height ratio and a target export size in
/// pixels (always 1080 px wide). The three presets cover the most common
/// social-media formats: Instagram Story (9:16), square post (1:1), and
/// portrait post (4:5).
library;

import 'package:flutter/material.dart';

enum AspectRatioPreset {
  story9x16('Story 9:16', 9, 16),
  post1x1('Post 1:1', 1, 1),
  post4x5('Post 4:5', 4, 5);

  const AspectRatioPreset(this.label, this.width, this.height);

  final String label;
  final int width;
  final int height;

  double get ratio => width / height;

  Size sizeFor(double logicalWidth) {
    final h = logicalWidth / ratio;
    return Size(logicalWidth, h);
  }

  Size get targetExportSize {
    switch (this) {
      case AspectRatioPreset.story9x16:
        return const Size(1080, 1920);
      case AspectRatioPreset.post1x1:
        return const Size(1080, 1080);
      case AspectRatioPreset.post4x5:
        return const Size(1080, 1350);
    }
  }
}
