/// Decodes a Google-encoded polyline and renders the route as a [CustomPaint] path.
///
/// Used in the frame editor to overlay the activity route on the preview.
/// Coordinates are projected to the bounding box with padding so the route
/// fills the available space regardless of geographic extent.
library;

import 'package:flutter/material.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class RoutePainter extends StatelessWidget {
  const RoutePainter({
    super.key,
    required this.polyline,
    this.color = Colors.white,
    this.strokeWidth = 3.0,
  });

  final String polyline;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final coordinates = decodePolyline(polyline);
    if (coordinates.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _RouteCustomPainter(
        coordinates: coordinates,
        color: color,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _RouteCustomPainter extends CustomPainter {
  _RouteCustomPainter({
    required this.coordinates,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<num>> coordinates;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.isEmpty) return;

    double minLatitude = coordinates[0][0].toDouble();
    double maxLatitude = coordinates[0][0].toDouble();
    double minLongitude = coordinates[0][1].toDouble();
    double maxLongitude = coordinates[0][1].toDouble();

    for (final coordinate in coordinates) {
      final latitude = coordinate[0].toDouble();
      final longitude = coordinate[1].toDouble();
      if (latitude < minLatitude) minLatitude = latitude;
      if (latitude > maxLatitude) maxLatitude = latitude;
      if (longitude < minLongitude) minLongitude = longitude;
      if (longitude > maxLongitude) maxLongitude = longitude;
    }

    final latitudeRange = maxLatitude - minLatitude;
    final longitudeRange = maxLongitude - minLongitude;
    if (latitudeRange == 0 && longitudeRange == 0) return;

    final padding = 16.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    final scaleX = longitudeRange > 0 ? drawWidth / longitudeRange : 0;
    final scaleY = latitudeRange > 0 ? drawHeight / latitudeRange : 0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final centerOffsetX = padding + (drawWidth - longitudeRange * scale) / 2;
    final centerOffsetY = padding + (drawHeight - latitudeRange * scale) / 2;

    final path = Path();
    for (var i = 0; i < coordinates.length; i++) {
      final latitude = coordinates[i][0].toDouble();
      final longitude = coordinates[i][1].toDouble();
      final x = centerOffsetX + (longitude - minLongitude) * scale;
      final y = centerOffsetY + (maxLatitude - latitude) * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RouteCustomPainter oldDelegate) {
    return oldDelegate.coordinates != coordinates ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
