/// Displays a single stat label + value pair on the frame overlay.
///
/// Renders the label in small uppercase text and the value in large bold
/// text, used for distance, duration, pace, watts, heart rate, and
/// elevation blocks. In edit mode, shows a delete button at the
/// top-right corner.
library;

import 'package:flutter/material.dart';

class StatBlockWidget extends StatelessWidget {
  const StatBlockWidget({
    super.key,
    required this.label,
    required this.value,
    this.labelColor = Colors.white70,
    this.valueColor = Colors.white,
    this.scale = 1.0,
    this.editMode = false,
    this.onDelete,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  /// Uniform scale factor applied to all text sizes, spacing, and padding
  /// so the block lays out at its true scaled size (no paint-only transform).
  final double scale;

  final bool editMode;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 1.2 * scale,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (editMode && onDelete != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
