import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/liquid_glass.dart';

void main() {
  testWidgets('static mesh background does not allocate a blur filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const LiquidGlassBackground(child: SizedBox.expand()),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('real blur remains opt-in for compact fixed surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const Scaffold(
          body: LiquidGlassSurface(
            blur: true,
            child: SizedBox(width: 200, height: 80),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('hero glass renders safely in both light and dark mode', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: brightness,
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                height: 160,
                child: LiquidGlassSurface(
                  blur: true,
                  variant: LiquidGlassVariant.hero,
                  child: Center(child: Text('Musify')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Musify'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('glass palette makes the selected accent visibly more vivid', () {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: brightness,
      );
      final palette = LiquidGlassPalette.from(scheme);
      final sourceSaturation = HSLColor.fromColor(scheme.primary).saturation;
      final vividSaturation = HSLColor.fromColor(palette.vividAccent)
          .saturation;

      expect(vividSaturation, greaterThanOrEqualTo(sourceSaturation));
    }
  });

  test('glass text contrast remains above WCAG AA in light and dark', () {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      );
      final alpha = brightness == Brightness.dark ? 0.68 : 0.76;
      final glass = Color.alphaBlend(
        scheme.surfaceContainerHigh.withValues(alpha: alpha),
        scheme.surface,
      );

      expect(
        _contrastRatio(scheme.onSurface, glass),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('confirmation modal keeps actions and uses one bounded blur', (
    tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ConfirmationDialog(
            confirmationMessage: 'Confermi?',
            submitMessage: 'Conferma',
            onCancel: () => cancelled = true,
            onSubmit: () {},
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Confermi?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    expect(cancelled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = math.max(firstLuminance, secondLuminance);
  final darker = math.min(firstLuminance, secondLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
