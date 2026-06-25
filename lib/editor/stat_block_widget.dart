/// Displays a single stat label + value pair on the frame overlay.
///
/// Renders the label in small uppercase text and the value in large bold
/// text, used for distance, duration, pace, watts, heart rate, and
/// elevation blocks.
library;

import 'package:flutter/material.dart';

class StatBlockWidget extends StatelessWidget {
  const StatBlockWidget({
    super.key,
    required this.label,
    required this.value,
    this.labelColor = Colors.white70,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
