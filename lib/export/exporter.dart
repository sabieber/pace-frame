/// Captures a [RepaintBoundary] as a PNG and shares it via the system share sheet.
///
/// The `pixelRatio` parameter controls output resolution — pass
/// `targetExportSize.width / logicalWidth` to get pixel-perfect exports
/// matching the chosen aspect-ratio preset (e.g. 1080×1920 for Story).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportAndShare(
  GlobalKey boundaryKey, {
  required double pixelRatio,
  String fileName = 'pace-frame.png',
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  final tempDir = await getTemporaryDirectory();
  final filePath = p.join(tempDir.path, fileName);
  final file = File(filePath);
  await file.writeAsBytes(byteData.buffer.asUint8List());

  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath)], text: 'Check out my activity!'),
  );
}
