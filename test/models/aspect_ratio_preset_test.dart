import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/models/aspect_ratio_preset.dart';

void main() {
  group('AspectRatioPreset', () {
    group('ratio', () {
      test('story9x16 has ratio 9/16', () {
        expect(AspectRatioPreset.story9x16.ratio, 9 / 16);
      });

      test('post1x1 has ratio 1.0', () {
        expect(AspectRatioPreset.post1x1.ratio, 1.0);
      });

      test('post4x5 has ratio 4/5', () {
        expect(AspectRatioPreset.post4x5.ratio, 4 / 5);
      });
    });

    group('sizeFor', () {
      test('story9x16 computes correct height for given width', () {
        final size = AspectRatioPreset.story9x16.sizeFor(360);
        expect(size.width, 360);
        expect(size.height, 640);
      });

      test('post1x1 returns square', () {
        final size = AspectRatioPreset.post1x1.sizeFor(500);
        expect(size.width, 500);
        expect(size.height, 500);
      });

      test('post4x5 computes correct height', () {
        final size = AspectRatioPreset.post4x5.sizeFor(400);
        expect(size.width, 400);
        expect(size.height, 500);
      });
    });

    group('targetExportSize', () {
      test('story9x16 exports at 1080x1920', () {
        const expected = Size(1080, 1920);
        expect(AspectRatioPreset.story9x16.targetExportSize, expected);
      });

      test('post1x1 exports at 1080x1080', () {
        const expected = Size(1080, 1080);
        expect(AspectRatioPreset.post1x1.targetExportSize, expected);
      });

      test('post4x5 exports at 1080x1350', () {
        const expected = Size(1080, 1350);
        expect(AspectRatioPreset.post4x5.targetExportSize, expected);
      });

      test('all presets are 1080px wide', () {
        for (final preset in AspectRatioPreset.values) {
          expect(preset.targetExportSize.width, 1080);
        }
      });
    });

    test('label is human-readable', () {
      expect(AspectRatioPreset.story9x16.label, 'Story 9:16');
      expect(AspectRatioPreset.post1x1.label, 'Post 1:1');
      expect(AspectRatioPreset.post4x5.label, 'Post 4:5');
    });
  });
}
