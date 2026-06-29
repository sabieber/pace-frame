import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recent_colors_provider.dart';

Future<Color?> showFrameColorPicker({
  required BuildContext context,
  required Color initialColor,
  required String title,
}) {
  return showDialog<Color>(
    context: context,
    builder: (dialogContext) => _FrameColorPickerDialog(
      initialColor: initialColor,
      title: title,
    ),
  );
}

class _FrameColorPickerDialog extends ConsumerStatefulWidget {
  const _FrameColorPickerDialog({
    required this.initialColor,
    required this.title,
  });

  final Color initialColor;
  final String title;

  @override
  ConsumerState<_FrameColorPickerDialog> createState() =>
      _FrameColorPickerDialogState();
}

class _FrameColorPickerDialogState
    extends ConsumerState<_FrameColorPickerDialog> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final recentColors = ref.watch(recentColorsProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() => _currentColor = color);
              },
              pickerAreaHeightPercent: 0.7,
              enableAlpha: true,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaBorderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2.0),
                topRight: Radius.circular(2.0),
              ),
            ),
            if (recentColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recently Used',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recentColors.map((color) {
                  final isSelected = _currentColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentColor = color);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(recentColorsProvider.notifier).addColor(_currentColor);
            Navigator.of(context).pop(_currentColor);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
