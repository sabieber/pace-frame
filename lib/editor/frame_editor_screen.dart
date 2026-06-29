/// Frame editor screen — compose a shareable image from a Strava activity.
///
/// Renders a fixed-size preview inside a [RepaintBoundary] with a colored
/// or image background, an optional route outline (via [RoutePainter]),
/// and draggable stat widgets. A bottom toolbar lets the user switch
/// aspect-ratio presets, pick backgrounds, add widgets, and toggle the
/// route. Widgets can be freely positioned via drag-and-drop and deleted
/// via a corner button. Export captures the boundary at target pixel
/// ratio and shares via the system share sheet.
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
  bool _editMode = true;
  int? _draggingId;
  double _dragDx = 0;
  double _dragDy = 0;
  final _widgetKeys = <int, GlobalKey>{};
  Size _dragWidgetSize = Size.zero;

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

  Widget _buildDraggableWidget(FrameWidget widget, Size logicalSize) {
    final baseDx = widget.position.dx * logicalSize.width;
    final baseDy = widget.position.dy * logicalSize.height;
    final dx = widget.id == _draggingId ? baseDx + _dragDx : baseDx;
    final dy = widget.id == _draggingId ? baseDy + _dragDy : baseDy;

    final key = _widgetKeys.putIfAbsent(widget.id, GlobalKey.new);

    return Positioned(
      key: ValueKey(widget.id),
      left: dx,
      top: dy,
      child: GestureDetector(
        onPanStart: (_) {
          final box = key.currentContext?.findRenderObject() as RenderBox?;
          _dragWidgetSize = box?.size ?? Size.zero;
          setState(() {
            _draggingId = widget.id;
            _dragDx = 0;
            _dragDy = 0;
          });
        },
        onPanUpdate: (details) {
          final maxDx = logicalSize.width - baseDx - _dragWidgetSize.width;
          final maxDy = logicalSize.height - baseDy - _dragWidgetSize.height;
          final newDx = (_dragDx + details.delta.dx).clamp(-baseDx, maxDx);
          final newDy = (_dragDy + details.delta.dy).clamp(-baseDy, maxDy);
          setState(() {
            _dragDx = newDx;
            _dragDy = newDy;
          });
        },
        onPanEnd: (_) {
          final newX = (baseDx + _dragDx) / logicalSize.width;
          final newY = (baseDy + _dragDy) / logicalSize.height;
          ref
              .read(frameConfigProvider.notifier)
              .moveWidget(
                widget.id,
                Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0)),
              );
          setState(() => _draggingId = null);
        },
        child: KeyedSubtree(
          key: key,
          child: StatBlockWidget(
            label: _labelFor(widget.type),
            value: _valueFor(widget.type),
            editMode: _editMode,
            onDelete: _editMode
                ? () => ref
                      .read(frameConfigProvider.notifier)
                      .removeWidget(widget.id)
                : null,
          ),
        ),
      ),
    );
  }

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
    final presentTypes = config.widgets.map((w) => w.type).toSet();
    final available = StatBlockType.values
        .where((t) => !presentTypes.contains(t))
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
                  onChanged: (v) => setModalState(() => showRoute = v),
                ),
                SwitchListTile(
                  title: const Text('Trim Endpoints'),
                  subtitle: const Text('Hide start/end for privacy'),
                  value: trimEndpoints,
                  onChanged: (v) => setModalState(() => trimEndpoints = v),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _editMode = true);
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
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
