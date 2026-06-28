import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pace_frame/editor/stat_block_widget.dart';

void main() {
  group('StatBlockWidget', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(label: 'Distance', value: '10.5 km'),
          ),
        ),
      );

      expect(find.text('DISTANCE'), findsOneWidget);
      expect(find.text('10.5 km'), findsOneWidget);
    });

    testWidgets('uppercases the label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(label: 'avg pace', value: '5:30'),
          ),
        ),
      );

      expect(find.text('AVG PACE'), findsOneWidget);
    });

    testWidgets('applies custom colors', (tester) async {
      const labelColor = Colors.orange;
      const valueColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(
              label: 'Watts',
              value: '250W',
              labelColor: labelColor,
              valueColor: valueColor,
            ),
          ),
        ),
      );

      final labelFinder = find.text('WATTS');
      final valueFinder = find.text('250W');
      expect(labelFinder, findsOneWidget);
      expect(valueFinder, findsOneWidget);

      final labelText = tester.widget<Text>(labelFinder);
      expect(labelText.style?.color, labelColor);

      final valueText = tester.widget<Text>(valueFinder);
      expect(valueText.style?.color, valueColor);
    });

    testWidgets('uses default white colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(label: 'HR', value: '155 bpm'),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('HR'));
      expect(labelText.style?.color, Colors.white70);

      final valueText = tester.widget<Text>(find.text('155 bpm'));
      expect(valueText.style?.color, Colors.white);
    });

    testWidgets('label uses small font size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(label: 'Elevation', value: '500m'),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('ELEVATION'));
      expect(labelText.style?.fontSize, 10);
    });

    testWidgets('value uses bold font', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlockWidget(label: 'Time', value: '1h 30m'),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('1h 30m'));
      expect(valueText.style?.fontWeight, FontWeight.bold);
    });
  });
}
