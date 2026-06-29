/// Frame editor screen — compose a shareable image from a Strava activity.
///
/// Renders a fixed-size preview inside a [RepaintBoundary] with a colored
/// or image background, an optional route outline (via [RoutePainter]),
/// and freely-positioned stat widgets. A bottom toolbar lets the user
/// switch aspect-ratio presets, pick backgrounds, add new widgets, and
/// toggle the route.
///
/// ## Widget interaction
///
/// Widgets are placed and moved via drag-and-drop. During a drag the
/// widget tracks the finger 1:1 — its position is never modified
/// mid-gesture. Alignment guide lines (see [_SnapGuide]) appear as
/// visual feedback when the dragged widget's edges or center line up
/// with those of other widgets or the frame itself.
///
/// **Snap-on-release**: when the user lifts their finger the widget
/// snaps to the closest alignment target if it is within
/// [_kSnapReleaseThreshold] pixels. Because the threshold is small
/// (3 px) the resulting jump is imperceptible.
///
/// **Drag-bounds clamping**: the widget's top-left corner is clamped to
/// `[0, frameWidth - widgetWidth]` × `[0, frameHeight - widgetHeight]`
/// so it cannot be dragged outside the frame.
///
/// ## Export
///
/// Export disables [_editMode], waits for a frame paint, captures the
/// [RepaintBoundary] at the target pixel ratio and shares via the
/// system share sheet. Edit-mode chrome (delete buttons) is hidden
/// during capture.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/database.dart';
import '../export/exporter.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/frame_config.dart';
import 'detail_polyline_provider.dart';
import 'frame_config_provider.dart';
import 'route_painter.dart';
import 'stat_block_widget.dart';

class FrameEditorScreen extends ConsumerStatefulWidget {
  const FrameEditorScreen({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<FrameEditorScreen> createState() => _FrameEditorScreenState();
}

class _FrameEditorScreenState extends ConsumerState<FrameEditorScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  /// When false, edit-mode chrome (delete buttons) is hidden.
  /// Toggled off during export capture.
  bool _editMode = true;

  // -- drag state -----------------------------------------------------------

  /// ID of the widget currently being dragged, or null.
  int? _draggingId;

  /// Pixel offset from the widget's committed position during a drag.
  double _dragDx = 0;
  double _dragDy = 0;

  /// Cumulative drag distance (sum of `delta.distance`), used to gate
  /// the onset of snap guide display.
  double _dragDistance = 0;

  // -- widget measurement ---------------------------------------------------

  /// GlobalKeys attached to each widget's subtree for render-box lookup.
  final _widgetKeys = <int, GlobalKey>{};

  /// Cached rendered sizes, refreshed at the start of each drag.
  final _widgetSizes = <int, Size>{};

  /// Rendered size of the currently dragged widget.
  Size _dragWidgetSize = Size.zero;

  // -- snap guides ----------------------------------------------------------

  /// Active snap guide lines to display in the preview overlay.
  List<_SnapGuide> _snapGuides = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(frameConfigProvider.notifier)
          .update(FrameConfig(activityId: widget.activity.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(frameConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _export(context),
            tooltip: 'Export & Share',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreview(config)),
          _buildToolbar(context, config),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  Widget _buildPreview(FrameConfig config) {
    final logicalSize = config.aspectRatio.sizeFor(
      MediaQuery.of(context).size.width - 32,
    );
    final polylineAsync = ref.watch(detailPolylineProvider(widget.activity.id));

    return Center(
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox.fromSize(
          size: logicalSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(config),
                if (config.showRoute)
                  polylineAsync.when(
                    data: (polyline) {
                      if (polyline == null) return const SizedBox.shrink();
                      return Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: RoutePainter(
                            polyline: polyline,
                            trimEndpoints: config.trimEndpoints,
                          ),
                        ),
                      );
                    },
                    loading: () => widget.activity.summaryPolyline != null
                        ? Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: RoutePainter(
                                polyline: widget.activity.summaryPolyline!,
                                trimEndpoints: config.trimEndpoints,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    error: (_, _) => widget.activity.summaryPolyline != null
                        ? Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: RoutePainter(
                                polyline: widget.activity.summaryPolyline!,
                                trimEndpoints: config.trimEndpoints,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                Positioned(left: 0, right: 0, top: 0, child: _buildHeader()),
                for (final widget in config.widgets)
                  _buildDraggableWidget(widget, logicalSize),
                if (_snapGuides.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SnapGuidePainter(_snapGuides),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(FrameConfig config) {
    if (config.background.type == BackgroundType.image &&
        config.background.imagePath != null) {
      return Image.file(File(config.background.imagePath!), fit: BoxFit.cover);
    }
    return Container(color: config.background.color);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
        ),
      ),
      child: Text(
        widget.activity.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Draggable widget
  // ---------------------------------------------------------------------------

  /// Wraps a [StatBlockWidget] in a [Positioned] + [GestureDetector] that
  /// handles drag-and-drop with bounds clamping and snap guide display.
  Widget _buildDraggableWidget(FrameWidget fw, Size logicalSize) {
    final baseDx = fw.position.dx * logicalSize.width;
    final baseDy = fw.position.dy * logicalSize.height;
    final dx = fw.id == _draggingId ? baseDx + _dragDx : baseDx;
    final dy = fw.id == _draggingId ? baseDy + _dragDy : baseDy;

    final key = _widgetKeys.putIfAbsent(fw.id, GlobalKey.new);

    return Positioned(
      key: ValueKey(fw.id),
      left: dx,
      top: dy,
      child: GestureDetector(
        onPanStart: (_) => _onDragStart(fw.id, key),
        onPanUpdate: (details) => _onDragUpdate(
          details,
          baseDx: baseDx,
          baseDy: baseDy,
          logicalSize: logicalSize,
        ),
        onPanEnd: (_) => _onDragEnd(
          fw.id,
          baseDx: baseDx,
          baseDy: baseDy,
          logicalSize: logicalSize,
        ),
        child: KeyedSubtree(
          key: key,
          child: StatBlockWidget(
            label: _labelFor(fw.type),
            value: _valueFor(fw.type),
            editMode: _editMode,
            onDelete: _editMode
                ? () =>
                      ref.read(frameConfigProvider.notifier).removeWidget(fw.id)
                : null,
          ),
        ),
      ),
    );
  }

  /// Captures the rendered size of every widget so that snap calculations
  /// have accurate geometry for the duration of the drag.
  void _onDragStart(int id, GlobalKey key) {
    for (final frameWidget in ref.read(frameConfigProvider).widgets) {
      final box =
          _widgetKeys[frameWidget.id]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (box != null && box.hasSize) {
        _widgetSizes[frameWidget.id] = box.size;
      }
    }
    _dragWidgetSize = _widgetSizes[id] ?? Size.zero;
    setState(() {
      _draggingId = id;
      _dragDx = 0;
      _dragDy = 0;
      _dragDistance = 0;
      _snapGuides = const [];
    });
  }

  /// Moves the widget with the finger, clamps to frame bounds, and
  /// displays alignment guide lines once the onset threshold is exceeded.
  /// The widget position is **never** modified during the drag — only
  /// visual guides are shown.
  void _onDragUpdate(
    DragUpdateDetails details, {
    required double baseDx,
    required double baseDy,
    required Size logicalSize,
  }) {
    _dragDistance += details.delta.distance;
    final rawDx = _dragDx + details.delta.dx;
    final rawDy = _dragDy + details.delta.dy;

    final guides = _dragDistance > _kSnapOnsetThreshold
        ? _findGuides(
            currentX: baseDx + rawDx,
            currentY: baseDy + rawDy,
            logicalSize: logicalSize,
          )
        : const <_SnapGuide>[];

    final maxDx = logicalSize.width - baseDx - _dragWidgetSize.width;
    final maxDy = logicalSize.height - baseDy - _dragWidgetSize.height;
    setState(() {
      _dragDx = rawDx.clamp(-baseDx, maxDx);
      _dragDy = rawDy.clamp(-baseDy, maxDy);
      _snapGuides = guides;
    });
  }

  /// Commits the widget's final position to the model. If the released
  /// position is within [_kSnapReleaseThreshold] of an alignment target
  /// the widget snaps to it (imperceptible jump ≤ 3 px).
  void _onDragEnd(
    int id, {
    required double baseDx,
    required double baseDy,
    required Size logicalSize,
  }) {
    final currentX = baseDx + _dragDx;
    final currentY = baseDy + _dragDy;
    final targets = _snapTargets(logicalSize);

    final snapDx = _closestSnapDelta(
      [
        currentX,
        currentX + _dragWidgetSize.width,
        currentX + _dragWidgetSize.width / 2,
      ],
      targets.horizontal,
      _kSnapReleaseThreshold,
    );
    final snapDy = _closestSnapDelta(
      [
        currentY,
        currentY + _dragWidgetSize.height,
        currentY + _dragWidgetSize.height / 2,
      ],
      targets.vertical,
      _kSnapReleaseThreshold,
    );

    final finalX = currentX + snapDx;
    final finalY = currentY + snapDy;

    ref
        .read(frameConfigProvider.notifier)
        .moveWidget(
          id,
          Offset(
            (finalX / logicalSize.width).clamp(0.0, 1.0),
            (finalY / logicalSize.height).clamp(0.0, 1.0),
          ),
        );
    setState(() {
      _draggingId = null;
      _snapGuides = const [];
    });
  }

  // ---------------------------------------------------------------------------
  // Snap helpers
  // ---------------------------------------------------------------------------

  /// Collects all horizontal and vertical snap-target positions from the
  /// frame edges, frame center lines, and every other widget's edges and
  /// center lines. Excludes the widget currently being dragged.
  _SnapTargetSet _snapTargets(Size logicalSize) {
    final xTargets = <double>[0, logicalSize.width / 2, logicalSize.width];
    final yTargets = <double>[0, logicalSize.height / 2, logicalSize.height];

    for (final other in ref.read(frameConfigProvider).widgets) {
      if (other.id == _draggingId) continue;
      final otherSize = _widgetSizes[other.id];
      if (otherSize == null) continue;
      final otherX = other.position.dx * logicalSize.width;
      final otherY = other.position.dy * logicalSize.height;
      xTargets.addAll([
        otherX,
        otherX + otherSize.width / 2,
        otherX + otherSize.width,
      ]);
      yTargets.addAll([
        otherY,
        otherY + otherSize.height / 2,
        otherY + otherSize.height,
      ]);
    }

    return _SnapTargetSet(horizontal: xTargets, vertical: yTargets);
  }

  /// Returns the smallest delta that moves any of [edges] (left/center/right
  /// or top/center/bottom) to a target in [targets], provided the distance
  /// is strictly less than [threshold]. Returns `0.0` when nothing is
  /// within range.
  double _closestSnapDelta(
    List<double> edges,
    List<double> targets,
    double threshold,
  ) {
    var minDist = threshold;
    var bestDelta = 0.0;
    for (final target in targets) {
      for (final edge in edges) {
        final delta = target - edge;
        if (delta.abs() < minDist) {
          minDist = delta.abs();
          bestDelta = delta;
        }
      }
    }
    return bestDelta;
  }

  /// Builds the list of snap guides to display during a drag.
  /// Checks each axis independently and keeps at most one guide per axis
  /// (the closest alignment).
  List<_SnapGuide> _findGuides({
    required double currentX,
    required double currentY,
    required Size logicalSize,
  }) {
    final targets = _snapTargets(logicalSize);
    final guides = <_SnapGuide>[];

    final snapDx = _closestSnapDelta(
      [
        currentX,
        currentX + _dragWidgetSize.width,
        currentX + _dragWidgetSize.width / 2,
      ],
      targets.horizontal,
      _kSnapThreshold,
    );
    if (snapDx != 0.0) {
      guides.add(_SnapGuide(_SnapAxis.vertical, currentX + snapDx));
    }

    final snapDy = _closestSnapDelta(
      [
        currentY,
        currentY + _dragWidgetSize.height,
        currentY + _dragWidgetSize.height / 2,
      ],
      targets.vertical,
      _kSnapThreshold,
    );
    if (snapDy != 0.0) {
      guides.add(_SnapGuide(_SnapAxis.horizontal, currentY + snapDy));
    }

    return guides;
  }

  // ---------------------------------------------------------------------------
  // Stat block display helpers
  // ---------------------------------------------------------------------------

  String _labelFor(StatBlockType type) {
    return switch (type) {
      StatBlockType.distance => 'Distance',
      StatBlockType.duration => 'Duration',
      StatBlockType.avgPace => 'Pace',
      StatBlockType.avgWatts => 'Avg Power',
      StatBlockType.avgHr => 'Avg HR',
      StatBlockType.elevation => 'Elevation',
    };
  }

  String _valueFor(StatBlockType type) {
    final activity = widget.activity;
    switch (type) {
      case StatBlockType.distance:
        return '${(activity.distance / 1000).toStringAsFixed(1)} km';
      case StatBlockType.duration:
        return _formatDuration(activity.movingTime);
      case StatBlockType.avgPace:
        if (activity.distance <= 0) return '—';
        final pace = activity.movingTime / (activity.distance / 1000);
        final mins = pace ~/ 60;
        final secs = (pace % 60).round();
        return '$mins:${secs.toString().padLeft(2, '0')} /km';
      case StatBlockType.avgWatts:
        return activity.averageWatts != null
            ? '${activity.averageWatts!.round()} W'
            : '—';
      case StatBlockType.avgHr:
        return activity.averageHeartRate != null
            ? '${activity.averageHeartRate!.round()} bpm'
            : '—';
      case StatBlockType.elevation:
        return activity.elevationGain != null
            ? '${activity.elevationGain!.round()} m'
            : '—';
    }
  }

  // ---------------------------------------------------------------------------
  // Toolbar & bottom sheets
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(BuildContext context, FrameConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.aspect_ratio,
            label: 'Ratio',
            onTap: () => _showRatioPicker(context, config),
          ),
          _ToolbarButton(
            icon: Icons.palette,
            label: 'Background',
            onTap: () => _showBackgroundPicker(context, config),
          ),
          _ToolbarButton(
            icon: Icons.add_circle_outline,
            label: 'Add',
            onTap: () => _showAddWidgetSheet(context, config),
          ),
          _ToolbarButton(
            icon: config.showRoute ? Icons.route : Icons.route_outlined,
            label: 'Route',
            onTap: () => _showRouteOptions(context, config),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetSheet(BuildContext context, FrameConfig config) {
    final presentTypes = config.widgets.map((widget) => widget.type).toSet();
    final available = StatBlockType.values
        .where((type) => !presentTypes.contains(type))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All stat blocks are already added')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Add Widget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...available.map((type) {
              return ListTile(
                title: Text(_labelFor(type)),
                onTap: () {
                  ref.read(frameConfigProvider.notifier).addWidget(type);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showRatioPicker(BuildContext context, FrameConfig config) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AspectRatioPreset.values.map((preset) {
            return ListTile(
              title: Text(preset.label),
              trailing: preset == config.aspectRatio
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref
                    .read(frameConfigProvider.notifier)
                    .update(config.copyWith(aspectRatio: preset));
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRouteOptions(BuildContext context, FrameConfig config) {
    var showRoute = config.showRoute;
    var trimEndpoints = config.trimEndpoints;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Route Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Show Route'),
                  value: showRoute,
                  onChanged: (value) => setModalState(() => showRoute = value),
                ),
                SwitchListTile(
                  title: const Text('Trim Endpoints'),
                  subtitle: const Text('Hide start/end for privacy'),
                  value: trimEndpoints,
                  onChanged: (value) =>
                      setModalState(() => trimEndpoints = value),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(frameConfigProvider.notifier)
                          .update(
                            config.copyWith(
                              showRoute: showRoute,
                              trimEndpoints: trimEndpoints,
                            ),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBackgroundPicker(BuildContext context, FrameConfig config) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Color'),
              onTap: () {
                Navigator.pop(ctx);
                _showColorPicker(context, config);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Image from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) {
                  ref
                      .read(frameConfigProvider.notifier)
                      .update(
                        config.copyWith(
                          background: FrameBackground(
                            type: BackgroundType.image,
                            imagePath: image.path,
                            color: config.background.color,
                          ),
                        ),
                      );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (image != null) {
                  ref
                      .read(frameConfigProvider.notifier)
                      .update(
                        config.copyWith(
                          background: FrameBackground(
                            type: BackgroundType.image,
                            imagePath: image.path,
                            color: config.background.color,
                          ),
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, FrameConfig config) {
    const colors = [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
      Color(0xFF533483),
      Color(0xFFE94560),
      Color(0xFF2D2D2D),
      Color(0xFF1B4332),
      Color(0xFFD4A373),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((color) {
                  final isSelected = config.background.color == color;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(frameConfigProvider.notifier)
                          .update(
                            config.copyWith(
                              background: FrameBackground(
                                type: BackgroundType.color,
                                color: color,
                              ),
                            ),
                          );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade400,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Future<void> _export(BuildContext context) async {
    final config = ref.read(frameConfigProvider);
    final targetSize = config.aspectRatio.targetExportSize;
    final logicalSize = config.aspectRatio.sizeFor(
      MediaQuery.of(context).size.width - 32,
    );
    final pixelRatio = targetSize.width / logicalSize.width;

    setState(() => _editMode = false);
    await WidgetsBinding.instance.endOfFrame;

    try {
      await exportAndShare(_boundaryKey, pixelRatio: pixelRatio);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _editMode = true);
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    }
    return '${minutes}m ${remainingSeconds}s';
  }
}

// =============================================================================
// Private widgets
// =============================================================================

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Snap alignment
// =============================================================================

/// Maximum distance (px) at which a guide line appears during drag.
const _kSnapThreshold = 3.0;

/// Maximum distance (px) at which the widget snaps on finger release.
/// Kept equal to [_kSnapThreshold] so the guide line is a reliable
/// indicator: if you see the line, the snap will happen.
const _kSnapReleaseThreshold = 3.0;

/// Cumulative drag distance (px) required before snap guide detection
/// activates. Prevents spurious guides on touch-down.
const _kSnapOnsetThreshold = 8.0;

/// Axis of a snap guide line.
enum _SnapAxis { vertical, horizontal }

/// A single alignment guide line at [position] pixels along [axis].
class _SnapGuide {
  const _SnapGuide(this.axis, this.position);

  final _SnapAxis axis;
  final double position;
}

/// Horizontal and vertical snap target positions collected from the
/// frame bounds and other widgets.
class _SnapTargetSet {
  const _SnapTargetSet({required this.horizontal, required this.vertical});

  final List<double> horizontal;
  final List<double> vertical;
}

/// Draws dashed snap guide lines across the frame. Wrapped in
/// [IgnorePointer] by the caller so it does not interfere with gestures.
class _SnapGuidePainter extends CustomPainter {
  _SnapGuidePainter(this.guides);

  final List<_SnapGuide> guides;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      final path = Path();
      if (guide.axis == _SnapAxis.vertical) {
        var dashY = 0.0;
        while (dashY < size.height) {
          path.moveTo(guide.position, dashY);
          path.lineTo(guide.position, (dashY + 4).clamp(0.0, size.height));
          dashY += 8;
        }
      } else {
        var dashX = 0.0;
        while (dashX < size.width) {
          path.moveTo(dashX, guide.position);
          path.lineTo((dashX + 4).clamp(0.0, size.width), guide.position);
          dashX += 8;
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SnapGuidePainter old) => true;
}
