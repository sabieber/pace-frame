/// Frame editor screen — compose a shareable image from a Strava activity.
///
/// Renders a fixed-size preview inside a [RepaintBoundary] with a colored
/// or image background, an optional route outline (via [RoutePainter]),
/// and toggleable stat blocks. A bottom toolbar lets the user switch
/// aspect-ratio presets, pick backgrounds, and toggle individual stats.
/// Export captures the boundary at target pixel ratio and shares via
/// the system share sheet.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/database.dart';
import '../export/exporter.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/frame_config.dart';
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
                if (config.showRoute && widget.activity.summaryPolyline != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RoutePainter(
                        polyline: widget.activity.summaryPolyline!,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStatsOverlay(config),
                ),
                Positioned(left: 0, right: 0, top: 0, child: _buildHeader()),
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

  Widget _buildStatsOverlay(FrameConfig config) {
    final blocks = config.statBlocks.where((b) => b.enabled).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: blocks.map((b) => _statBlockFor(b.type)).toList(),
      ),
    );
  }

  Widget _statBlockFor(StatBlockType type) {
    final a = widget.activity;
    switch (type) {
      case StatBlockType.distance:
        return StatBlockWidget(
          label: 'Distance',
          value: '${(a.distance / 1000).toStringAsFixed(1)} km',
        );
      case StatBlockType.duration:
        return StatBlockWidget(
          label: 'Duration',
          value: _formatDuration(a.movingTime),
        );
      case StatBlockType.avgPace:
        if (a.distance <= 0) {
          return const StatBlockWidget(label: 'Pace', value: '—');
        }
        final pace = a.movingTime / (a.distance / 1000);
        final mins = pace ~/ 60;
        final secs = (pace % 60).round();
        return StatBlockWidget(
          label: 'Pace',
          value: '$mins:${secs.toString().padLeft(2, '0')} /km',
        );
      case StatBlockType.avgWatts:
        return StatBlockWidget(
          label: 'Avg Power',
          value: a.averageWatts != null ? '${a.averageWatts!.round()} W' : '—',
        );
      case StatBlockType.avgHr:
        return StatBlockWidget(
          label: 'Avg HR',
          value: a.averageHeartRate != null
              ? '${a.averageHeartRate!.round()} bpm'
              : '—',
        );
      case StatBlockType.elevation:
        return StatBlockWidget(
          label: 'Elevation',
          value: a.elevationGain != null
              ? '${a.elevationGain!.round()} m'
              : '—',
        );
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
            icon: Icons.bar_chart,
            label: 'Stats',
            onTap: () => _showStatsPicker(context, config),
          ),
          _ToolbarButton(
            icon: config.showRoute ? Icons.route : Icons.route_outlined,
            label: 'Route',
            onTap: () {
              ref
                  .read(frameConfigProvider.notifier)
                  .update(config.copyWith(showRoute: !config.showRoute));
            },
          ),
        ],
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

  void _showStatsPicker(BuildContext context, FrameConfig config) {
    final blocks = List<StatBlock>.from(config.statBlocks);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Stat Blocks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...blocks.asMap().entries.map((entry) {
                  final block = entry.value;
                  final label = switch (block.type) {
                    StatBlockType.distance => 'Distance',
                    StatBlockType.duration => 'Duration',
                    StatBlockType.avgPace => 'Avg Pace',
                    StatBlockType.avgWatts => 'Avg Power',
                    StatBlockType.avgHr => 'Avg Heart Rate',
                    StatBlockType.elevation => 'Elevation',
                  };
                  return SwitchListTile(
                    title: Text(label),
                    value: block.enabled,
                    onChanged: (v) {
                      setModalState(() {
                        blocks[entry.key] = block.copyWith(enabled: v);
                      });
                    },
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(frameConfigProvider.notifier)
                          .update(config.copyWith(statBlocks: blocks));
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
    );
  }

  Future<void> _export(BuildContext context) async {
    final config = ref.read(frameConfigProvider);
    final targetSize = config.aspectRatio.targetExportSize;
    final logicalSize = config.aspectRatio.sizeFor(
      MediaQuery.of(context).size.width - 32,
    );
    final pixelRatio = targetSize.width / logicalSize.width;

    try {
      await exportAndShare(_boundaryKey, pixelRatio: pixelRatio);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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
