/// Riverpod provider for the current [FrameConfig] in the editor.
///
/// The editor initialises the config in a post-frame callback after
/// navigating from the activity list, then mutations go through
/// [FrameConfigNotifier.update].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frame_config.dart';

class FrameConfigNotifier extends Notifier<FrameConfig> {
  @override
  FrameConfig build() => const FrameConfig(activityId: 0);

  void update(FrameConfig config) {
    state = config;
  }
}

final frameConfigProvider = NotifierProvider<FrameConfigNotifier, FrameConfig>(
  FrameConfigNotifier.new,
);
