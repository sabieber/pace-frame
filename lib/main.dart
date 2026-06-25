/// App entry point.
///
/// Wraps [PaceFrameApp] in a Riverpod [ProviderScope] so that all providers
/// declared in `providers.dart` are available throughout the widget tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PaceFrameApp()));
}
