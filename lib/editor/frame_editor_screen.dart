/// Frame editor screen — compose a shareable image from a Strava activity.
///
/// Renders a fixed-size preview inside a [RepaintBoundary] with a colored
/// or image background, and freely-positioned stat and route widgets.
/// A bottom toolbar lets the user switch aspect-ratio presets, pick
/// backgrounds, and add new widgets.
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
/// **Resize**: a grip handle in the bottom-right corner of each widget
/// (visible in edit mode) allows uniform scaling via drag. The scale is
/// anchored at the widget's center (which stays fixed — the top-left
/// [position] is updated each frame to compensate) and clamped to
/// [_kMinScale]–[_kMaxScale] as well as the frame bounds, so growth is
/// blocked once any edge reaches the frame. The scale factor is passed
/// down into the content widgets so they lay out at their true scaled
/// size — no paint-only [Transform], so the layout box, chrome buttons,
/// and hit-test region all track the scaled size.
///
/// ## Export
///
/// Export disables [_editMode], waits for a frame paint, captures the
/// [RepaintBoundary] at the target pixel ratio and shares via the
/// system share sheet. Edit-mode chrome (delete buttons, settings
/// buttons) is hidden during capture.
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
import 'frame_color_picker.dart';
import 'frame_config_provider.dart';
import 'route_widget.dart';
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

  // -- resize state ---------------------------------------------------------

  /// ID of the widget currently being resized, or null.
  int? _resizingId;

  /// Scale of the widget at the moment the resize gesture started.
  double _resizeStartScale = 1.0;

  /// Unscaled base size of the widget being resized.
  Size _resizeBaseSize = Size.zero;

  /// Pixel center of the widget being resized (fixed during resize so the
  /// widget grows/shrinks symmetrically around it).
  double _resizeCenterX = 0;
  double _resizeCenterY = 0;

  /// Initial distance from the center to the finger at resize start, used
  /// to derive the scale ratio.
  double _resizeStartDistance = 0;

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
    final resolvedPolyline = _resolvePolyline(polylineAsync);
    final routeWidgetSize = _routeWidgetSize(logicalSize);

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
                for (final frameWidget in config.widgets)
                  if (frameWidget.type == FrameWidgetType.route &&
                      resolvedPolyline != null)
                    _buildDraggableWidget(
                      frameWidget,
                      logicalSize,
                      polyline: resolvedPolyline,
                      routeWidgetSize: routeWidgetSize,
                    ),
                Positioned(left: 0, right: 0, top: 0, child: _buildHeader()),
                for (final frameWidget in config.widgets)
                  if (frameWidget.type != FrameWidgetType.route)
                    _buildDraggableWidget(frameWidget, logicalSize),
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

  String? _resolvePolyline(AsyncValue<String?> polylineAsync) {
    return polylineAsync.whenOrNull(data: (polyline) => polyline) ??
        widget.activity.summaryPolyline;
  }

  Size _routeWidgetSize(Size logicalSize) {
    final dimension = logicalSize.width * _kRouteSizeRatio;
    return Size(dimension, dimension);
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

  /// Wraps a widget in a [Positioned] + [GestureDetector] that
  /// handles drag-and-drop with bounds clamping and snap guide display.
  /// The widget's [scale] is passed into the content so it lays out at
  /// its true scaled size.
  ///
  /// Edit-mode controls (delete, route settings, resize handle) sit in a
  /// constant-width gutter ([_kChromeGutter]) around the content. The
  /// surrounding [Positioned] is shifted left/up by the gutter so the
  /// content's visual top-left still lands at `position * logicalSize`.
  /// Because the chrome lives **inside** the gutter — and therefore
  /// inside the gesture's hit-test bounds — it stays tappable at any
  /// scale, and tracks the content as it grows because the layout box
  /// reflects the real scaled size.
  ///
  /// The [GlobalKey] is attached to the content widget so that
  /// `findRenderObject()` returns its rendered (scaled) size for drag
  /// clamping, snapping, and resize calculations.
  Widget _buildDraggableWidget(
    FrameWidget frameWidget,
    Size logicalSize, {
    String? polyline,
    Size? routeWidgetSize,
  }) {
    final baseDx = frameWidget.position.dx * logicalSize.width;
    final baseDy = frameWidget.position.dy * logicalSize.height;
    final dx = frameWidget.id == _draggingId ? baseDx + _dragDx : baseDx;
    final dy = frameWidget.id == _draggingId ? baseDy + _dragDy : baseDy;

    final key = _widgetKeys.putIfAbsent(frameWidget.id, GlobalKey.new);
    final scale = frameWidget.scale;

    return Positioned(
      key: ValueKey(frameWidget.id),
      left: dx - _kChromeGutter,
      top: dy - _kChromeGutter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _onDragStart(frameWidget.id, key),
        onPanUpdate: (details) => _onDragUpdate(
          details,
          baseDx: baseDx,
          baseDy: baseDy,
          logicalSize: logicalSize,
        ),
        onPanEnd: (_) => _onDragEnd(
          frameWidget.id,
          baseDx: baseDx,
          baseDy: baseDy,
          logicalSize: logicalSize,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(_kChromeGutter),
              child: _buildWidgetContent(
                frameWidget,
                contentKey: key,
                polyline: polyline,
                routeWidgetSize: routeWidgetSize,
                scale: scale,
              ),
            ),
            if (_editMode) ...[
              Positioned(
                top: _kChromeGutter - 10,
                right: _kChromeGutter - 10,
                child: _buildDeleteButton(frameWidget.id),
              ),
              Positioned(
                top: _kChromeGutter - 10,
                left: _kChromeGutter - 10,
                child: _buildSettingsButton(frameWidget),
              ),
              Positioned(
                bottom: _kChromeGutter - 12,
                right: _kChromeGutter - 12,
                child: _buildResizeHandle(frameWidget.id, logicalSize),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Reads the rendered size of a widget via the render object attached
  /// to [key].
  Size _measureBaseSize(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box.size : Size.zero;
  }

  Widget _buildDeleteButton(int widgetId) {
    return GestureDetector(
      onTap: () =>
          ref.read(frameConfigProvider.notifier).removeWidget(widgetId),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildSettingsButton(FrameWidget frameWidget) {
    return GestureDetector(
      onTap: () {
        final config = ref.read(frameConfigProvider);
        if (frameWidget.type == FrameWidgetType.route) {
          _showRouteSettings(config, frameWidget.id);
        } else {
          _showStatSettings(config, frameWidget.id);
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.settings, size: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildResizeHandle(int widgetId, Size logicalSize) {
    return GestureDetector(
      onPanStart: (details) =>
          _onResizeStart(widgetId, logicalSize, details.globalPosition),
      onPanUpdate: (details) => _onResizeUpdate(details, logicalSize),
      onPanEnd: (_) => _onResizeEnd(),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          size: const Size(12, 12),
          painter: _ResizeGripPainter(),
        ),
      ),
    );
  }

  Widget _buildWidgetContent(
    FrameWidget frameWidget, {
    required Key contentKey,
    required double scale,
    String? polyline,
    Size? routeWidgetSize,
  }) {
    if (frameWidget.type == FrameWidgetType.route) {
      return RouteWidget(
        key: contentKey,
        polyline: polyline!,
        size: routeWidgetSize! * scale,
        trimEndpoints: frameWidget.trimEndpoints,
        routeColor: frameWidget.routeColor,
        editMode: _editMode,
      );
    }
    return StatBlockWidget(
      key: contentKey,
      label: _labelFor(frameWidget.type),
      value: _valueFor(frameWidget.type),
      scale: scale,
      showTitle: frameWidget.showTitle,
      showIcon: frameWidget.showIcon,
      icon: _iconFor(frameWidget.type),
      labelColor: frameWidget.titleColor,
      valueColor: frameWidget.valueColor,
      iconColor: frameWidget.iconColor,
      editMode: _editMode,
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
  // Resize
  // ---------------------------------------------------------------------------

  void _onResizeStart(int id, Size logicalSize, Offset fingerGlobal) {
    final frameWidget = ref
        .read(frameConfigProvider)
        .widgets
        .firstWhere((widget) => widget.id == id);

    final key = _widgetKeys[id];
    final renderedSize = key != null ? _measureBaseSize(key) : Size.zero;
    final startScale = frameWidget.scale;
    final baseSize = startScale > 0
        ? Size(renderedSize.width / startScale, renderedSize.height / startScale)
        : renderedSize;

    final centerX =
        frameWidget.position.dx * logicalSize.width + renderedSize.width / 2;
    final centerY =
        frameWidget.position.dy * logicalSize.height + renderedSize.height / 2;

    final renderBox =
        _boundaryKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final fingerLocal = fingerGlobal - origin;

    setState(() {
      _resizingId = id;
      _resizeStartScale = startScale;
      _resizeBaseSize = baseSize;
      _resizeCenterX = centerX;
      _resizeCenterY = centerY;
      _resizeStartDistance =
          (fingerLocal - Offset(centerX, centerY)).distance;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details, Size logicalSize) {
    if (_resizingId == null || _resizeStartDistance <= 0) return;

    final renderBox =
        _boundaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final origin = renderBox.localToGlobal(Offset.zero);
    final finger = details.globalPosition - origin;

    final currentDistance =
        (finger - Offset(_resizeCenterX, _resizeCenterY)).distance;
    final rawScale =
        _resizeStartScale * currentDistance / _resizeStartDistance;
    final clampedScale = _clampScale(
      rawScale,
      _resizeBaseSize,
      _resizeCenterX,
      _resizeCenterY,
      logicalSize,
    );

    final left = _resizeCenterX - _resizeBaseSize.width * clampedScale / 2;
    final top = _resizeCenterY - _resizeBaseSize.height * clampedScale / 2;

    ref.read(frameConfigProvider.notifier).resizeWidget(
      _resizingId!,
      clampedScale,
      Offset(left / logicalSize.width, top / logicalSize.height),
    );
  }

  void _onResizeEnd() {
    setState(() => _resizingId = null);
  }

  /// Clamps [scale] to [_kMinScale]–[_kMaxScale] and shrinks it further if
  /// growing the center-anchored widget would push any edge past the
  /// frame bounds, so growth stops once an edge reaches the frame.
  double _clampScale(
    double scale,
    Size baseSize,
    double centerX,
    double centerY,
    Size logicalSize,
  ) {
    var clamped = scale.clamp(_kMinScale, _kMaxScale);

    if (baseSize.width > 0 && baseSize.height > 0) {
      final maxScaleLeft = centerX * 2 / baseSize.width;
      final maxScaleRight = (logicalSize.width - centerX) * 2 / baseSize.width;
      final maxScaleTop = centerY * 2 / baseSize.height;
      final maxScaleBottom =
          (logicalSize.height - centerY) * 2 / baseSize.height;
      final maxScale = [
        maxScaleLeft,
        maxScaleRight,
        maxScaleTop,
        maxScaleBottom,
      ].reduce((value, element) => value < element ? value : element);
      if (clamped > maxScale) {
        clamped = maxScale.clamp(_kMinScale, _kMaxScale);
      }
    }

    return clamped;
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

  String _labelFor(FrameWidgetType type) {
    return switch (type) {
      FrameWidgetType.distance => 'Distance',
      FrameWidgetType.duration => 'Duration',
      FrameWidgetType.averagePace => 'Pace',
      FrameWidgetType.averageWatts => 'Avg Power',
      FrameWidgetType.averageHeartRate => 'Avg HR',
      FrameWidgetType.elevation => 'Elevation',
      FrameWidgetType.route => 'Route',
    };
  }

  IconData _iconFor(FrameWidgetType type) {
    return switch (type) {
      FrameWidgetType.distance => Icons.straighten,
      FrameWidgetType.duration => Icons.timer,
      FrameWidgetType.averagePace => Icons.speed,
      FrameWidgetType.averageWatts => Icons.bolt,
      FrameWidgetType.averageHeartRate => Icons.favorite,
      FrameWidgetType.elevation => Icons.terrain,
      FrameWidgetType.route => Icons.route,
    };
  }

  String _valueFor(FrameWidgetType type) {
    final activity = widget.activity;
    switch (type) {
      case FrameWidgetType.distance:
        return '${(activity.distance / 1000).toStringAsFixed(1)} km';
      case FrameWidgetType.duration:
        return _formatDuration(activity.movingTime);
      case FrameWidgetType.averagePace:
        if (activity.distance <= 0) return '—';
        final pace = activity.movingTime / (activity.distance / 1000);
        final mins = pace ~/ 60;
        final secs = (pace % 60).round();
        return '$mins:${secs.toString().padLeft(2, '0')} /km';
      case FrameWidgetType.averageWatts:
        return activity.averageWatts != null
            ? '${activity.averageWatts!.round()} W'
            : '—';
      case FrameWidgetType.averageHeartRate:
        return activity.averageHeartRate != null
            ? '${activity.averageHeartRate!.round()} bpm'
            : '—';
      case FrameWidgetType.elevation:
        return activity.elevationGain != null
            ? '${activity.elevationGain!.round()} m'
            : '—';
      case FrameWidgetType.route:
        return '';
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
        ],
      ),
    );
  }

  void _showAddWidgetSheet(BuildContext context, FrameConfig config) {
    final presentTypes = config.widgets.map((widget) => widget.type).toSet();
    final available = FrameWidgetType.values
        .where((type) => !presentTypes.contains(type))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All widgets are already added')),
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
                leading: Icon(_iconFor(type)),
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

  void _showRouteSettings(FrameConfig config, int routeWidgetId) {
    final routeWidget = config.widgets.firstWhere(
      (widget) => widget.id == routeWidgetId,
    );
    var trimEndpoints = routeWidget.trimEndpoints;
    var routeColor = routeWidget.routeColor;

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
                    'Route Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Trim Endpoints'),
                  subtitle: const Text('Hide start/end for privacy'),
                  value: trimEndpoints,
                  onChanged: (value) =>
                      setModalState(() => trimEndpoints = value),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Colors',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _ColorListTile(
                  label: 'Route Line Color',
                  color: routeColor,
                  onTap: () async {
                    final picked = await showFrameColorPicker(
                      context: ctx,
                      initialColor: routeColor,
                      title: 'Route Line Color',
                    );
                    if (picked != null) {
                      setModalState(() => routeColor = picked);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(frameConfigProvider.notifier)
                          .updateWidget(
                            routeWidgetId,
                            routeWidget.copyWith(
                              trimEndpoints: trimEndpoints,
                              routeColor: routeColor,
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

  void _showStatSettings(FrameConfig config, int statWidgetId) {
    final statWidget = config.widgets.firstWhere(
      (widget) => widget.id == statWidgetId,
    );
    var showTitle = statWidget.showTitle;
    var showIcon = statWidget.showIcon;
    var iconColor = statWidget.iconColor;
    var titleColor = statWidget.titleColor;
    var valueColor = statWidget.valueColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${_labelFor(statWidget.type)} Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show Title'),
                    value: showTitle,
                    onChanged: (value) =>
                        setModalState(() => showTitle = value),
                  ),
                  SwitchListTile(
                    title: const Text('Show Icon'),
                    value: showIcon,
                    onChanged: (value) =>
                        setModalState(() => showIcon = value),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Colors',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _ColorListTile(
                    label: 'Icon Color',
                    color: iconColor,
                    onTap: () async {
                      final picked = await showFrameColorPicker(
                        context: ctx,
                        initialColor: iconColor,
                        title: 'Icon Color',
                      );
                      if (picked != null) {
                        setModalState(() => iconColor = picked);
                      }
                    },
                  ),
                  _ColorListTile(
                    label: 'Title Color',
                    color: titleColor,
                    onTap: () async {
                      final picked = await showFrameColorPicker(
                        context: ctx,
                        initialColor: titleColor,
                        title: 'Title Color',
                      );
                      if (picked != null) {
                        setModalState(() => titleColor = picked);
                      }
                    },
                  ),
                  _ColorListTile(
                    label: 'Value Color',
                    color: valueColor,
                    onTap: () async {
                      final picked = await showFrameColorPicker(
                        context: ctx,
                        initialColor: valueColor,
                        title: 'Value Color',
                      );
                      if (picked != null) {
                        setModalState(() => valueColor = picked);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(frameConfigProvider.notifier)
                            .updateWidget(
                              statWidgetId,
                              statWidget.copyWith(
                                showTitle: showTitle,
                                showIcon: showIcon,
                                iconColor: iconColor,
                                titleColor: titleColor,
                                valueColor: valueColor,
                              ),
                            );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
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

  Future<void> _showColorPicker(BuildContext context, FrameConfig config) async {
    final picked = await showFrameColorPicker(
      context: context,
      initialColor: config.background.color,
      title: 'Background Color',
    );
    if (picked != null) {
      ref
          .read(frameConfigProvider.notifier)
          .update(
            config.copyWith(
              background: FrameBackground(
                type: BackgroundType.color,
                color: picked,
              ),
            ),
          );
    }
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

class _ColorListTile extends StatelessWidget {
  const _ColorListTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

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

/// Route widget size as a fraction of the frame's logical width.
const _kRouteSizeRatio = 0.55;

/// Transparent gutter (px) around each widget's content that houses the
/// edit-mode chrome (delete, settings, resize handle). Wide enough that
/// the corner buttons sit inside the gesture's hit-test bounds and stay
/// tappable. Must be ≥ 12 to fit the resize grip.
const _kChromeGutter = 14.0;

/// Minimum allowed widget scale (40% of base size).
const _kMinScale = 0.4;

/// Maximum allowed widget scale (200% of base size).
const _kMaxScale = 2.0;

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

/// Draws a diagonal grip pattern (three short lines) indicating a
/// resize affordance in the bottom-right corner of a widget.
class _ResizeGripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final lines = [
      Offset(size.width, size.height * 0.3),
      Offset(size.width * 0.3, size.height),
      Offset(size.width, size.height * 0.55),
      Offset(size.width * 0.55, size.height),
      Offset(size.width, size.height * 0.8),
      Offset(size.width * 0.8, size.height),
    ];

    for (var index = 0; index < lines.length; index += 2) {
      canvas.drawLine(lines[index], lines[index + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_ResizeGripPainter old) => false;
}
