/// Displays the activity route polyline as a draggable frame widget.
///
/// Renders the route inside a sized container with edit-mode controls:
/// delete button (top-right), settings button (top-left), and a
/// visibility toggle (bottom-right). The settings button opens a
/// bottom sheet where the user can toggle route visibility and
/// endpoint trimming.
library;

import 'package:flutter/material.dart';

import 'route_painter.dart';

class RouteWidget extends StatelessWidget {
  const RouteWidget({
    super.key,
    required this.polyline,
    required this.size,
    this.trimEndpoints = true,
    this.editMode = false,
    this.onDelete,
    this.onSettings,
  });

  final String polyline;
  final Size size;
  final bool trimEndpoints;
  final bool editMode;
  final VoidCallback? onDelete;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: editMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
              color: editMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RoutePainter(
                polyline: polyline,
                trimEndpoints: trimEndpoints,
              ),
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
          if (editMode && onSettings != null)
            Positioned(
              top: -6,
              left: -6,
              child: GestureDetector(
                onTap: onSettings,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
