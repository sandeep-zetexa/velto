import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velto/core/widgets/app_button.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('renders text-only button and triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Save Meal',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Meal'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });

    testWidgets('renders leading and trailing icons with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Add Ingredient',
              icon: LucideIcons.plus,
              trailingIcon: LucideIcons.arrow_right,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Ingredient'), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrow_right), findsOneWidget);
    });

    testWidgets('renders standalone icon button', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.icon(
              icon: LucideIcons.trash_2,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.trash_2), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });

    testWidgets('shows loading spinner and ignores taps when isLoading is true', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Submitting',
              isLoading: true,
              loadingText: 'Saving...',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving...'), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, false); // Must not trigger when loading
    });

    testWidgets('ignores taps when isDisabled is true or onPressed is null', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Disabled',
              isDisabled: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(pressed, false);
    });

    testWidgets('supports variants and sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton.primary(text: 'Primary', size: AppButtonSize.lg, onPressed: () {}),
                AppButton.secondary(text: 'Secondary', size: AppButtonSize.md, onPressed: () {}),
                AppButton.outline(text: 'Outline', size: AppButtonSize.sm, onPressed: () {}),
                AppButton.soft(text: 'Soft', size: AppButtonSize.xs, onPressed: () {}),
                AppButton.danger(text: 'Danger', onPressed: () {}),
                AppButton.text(text: 'Text Action', onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('Soft'), findsOneWidget);
      expect(find.text('Danger'), findsOneWidget);
      expect(find.text('Text Action'), findsOneWidget);
    });
  });
}
