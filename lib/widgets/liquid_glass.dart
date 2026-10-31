import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Visual hierarchy for premium glass surfaces.
///
/// [hero] is reserved for the few prominent cards on a page, [overlay] for
/// navigation and player chrome, while [standard] is the low-cost default.
/// Long scrolling lists must keep real blur disabled regardless of variant.
enum LiquidGlassVariant { standard, hero, overlay }

@immutable
class LiquidGlassPalette {
  const LiquidGlassPalette({
    required this.accent,
    required this.vividAccent,
    required this.deepAccent,
    required this.baseSurface,
    required this.specular,
  });

  factory LiquidGlassPalette.from(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final source = HSLColor.fromColor(colorScheme.primary);
    final vivid = source
        .withSaturation(
          (source.saturation + (isDark ? 0.20 : 0.14)).clamp(0, 1),
        )
        .withLightness(
          (source.lightness + (isDark ? 0.07 : -0.035)).clamp(
            isDark ? 0.48 : 0.32,
            isDark ? 0.72 : 0.58,
          ),
        )
        .toColor();
    final deep = source
        .withSaturation((source.saturation + 0.10).clamp(0, 1))
        .withLightness(
          (source.lightness + (isDark ? -0.18 : 0.13)).clamp(0.12, 0.88),
        )
        .toColor();

    return LiquidGlassPalette(
      accent: colorScheme.primary,
      vividAccent: vivid,
      deepAccent: deep,
      baseSurface: colorScheme.surfaceContainerHigh,
      specular: isDark ? Colors.white : colorScheme.onPrimary,
    );
  }

  final Color accent;
  final Color vividAccent;
  final Color deepAccent;
  final Color baseSurface;
  final Color specular;
}

/// Static, GPU-friendly aurora background shared by every mobile route.
///
/// The stronger color field gives the glass something meaningful to refract.
/// It is deliberately static and isolated in repaint boundaries so music lists
/// never pay for a continuously animated mesh.
class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final palette = LiquidGlassPalette.from(colorScheme);

    return ColoredBox(
      color: colorScheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      palette.deepAccent.withValues(
                        alpha: isDark ? 0.22 : 0.10,
                      ),
                      colorScheme.surface,
                    ),
                    Color.alphaBlend(
                      palette.vividAccent.withValues(
                        alpha: isDark ? 0.13 : 0.08,
                      ),
                      colorScheme.surface,
                    ),
                    Color.alphaBlend(
                      colorScheme.tertiary.withValues(
                        alpha: isDark ? 0.17 : 0.10,
                      ),
                      colorScheme.surface,
                    ),
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.94, -0.92),
                  radius: 1.06,
                  colors: [
                    palette.vividAccent.withValues(alpha: isDark ? 0.38 : 0.25),
                    palette.accent.withValues(alpha: isDark ? 0.12 : 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.05, 0.08),
                  radius: 0.92,
                  colors: [
                    colorScheme.tertiary.withValues(
                      alpha: isDark ? 0.23 : 0.15,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.25, 1.12),
                  radius: 0.95,
                  colors: [
                    palette.deepAccent.withValues(alpha: isDark ? 0.24 : 0.11),
                    Colors.transparent,
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
          // A neutral veil protects text contrast in both brightness modes.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: isDark ? 0.06 : 0.12),
                    Colors.transparent,
                    colorScheme.surface.withValues(alpha: isDark ? 0.18 : 0.10),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Reusable premium glass panel.
///
/// Real blur is opt-in and reserved for compact, fixed surfaces. The ambient
/// shadow intentionally lives outside the clipping layer, otherwise it would
/// be cut away and the panel would lose its depth.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.blur = false,
    this.blurSigma = 18,
    this.showShadow = true,
    this.variant = LiquidGlassVariant.standard,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final double blurSigma;
  final bool showShadow;
  final LiquidGlassVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final palette = LiquidGlassPalette.from(colorScheme);
    final isHero = variant == LiquidGlassVariant.hero;
    final isOverlay = variant == LiquidGlassVariant.overlay;

    final baseAlpha = switch (variant) {
      LiquidGlassVariant.hero => isDark ? 0.46 : 0.58,
      LiquidGlassVariant.overlay => isDark ? 0.57 : 0.68,
      LiquidGlassVariant.standard => isDark ? 0.62 : 0.72,
    };
    final tintAlpha = switch (variant) {
      LiquidGlassVariant.hero => isDark ? 0.24 : 0.16,
      LiquidGlassVariant.overlay => isDark ? 0.18 : 0.13,
      LiquidGlassVariant.standard => isDark ? 0.13 : 0.10,
    };
    final fill = palette.baseSurface.withValues(alpha: baseAlpha);

    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    Widget interior = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: isDark ? 0.13 : 0.48),
              fill,
            ),
            Color.alphaBlend(
              palette.vividAccent.withValues(alpha: tintAlpha),
              fill,
            ),
            Color.alphaBlend(
              palette.deepAccent.withValues(
                alpha: isDark ? tintAlpha * 0.72 : tintAlpha * 0.45,
              ),
              fill,
            ),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: RadialGradient(
                    center: const Alignment(-0.82, -0.95),
                    radius: 1,
                    colors: [
                      Colors.white.withValues(
                        alpha: isDark
                            ? (isHero ? 0.17 : 0.12)
                            : (isHero ? 0.55 : 0.42),
                      ),
                      palette.vividAccent.withValues(
                        alpha: isDark ? 0.06 : 0.035,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.34, 1],
                  ),
                ),
              ),
            ),
          ),
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlassRimPainter(
                  borderRadius: borderRadius,
                  brightColor: Colors.white.withValues(
                    alpha: isDark ? 0.38 : 0.84,
                  ),
                  accentColor: palette.vividAccent.withValues(
                    alpha: isDark ? 0.30 : 0.22,
                  ),
                  shadeColor: palette.deepAccent.withValues(
                    alpha: isDark ? 0.42 : 0.18,
                  ),
                  strokeWidth: isHero ? 1.25 : 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (blur) {
      interior = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: interior,
      );
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: palette.vividAccent.withValues(
                      alpha: isDark
                          ? (isHero ? 0.18 : 0.13)
                          : (isHero ? 0.15 : 0.10),
                    ),
                    blurRadius: isHero ? 42 : 32,
                    spreadRadius: isHero ? -2 : -4,
                    offset: Offset(0, isOverlay ? 10 : 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.16),
                    blurRadius: isHero ? 36 : 28,
                    spreadRadius: -3,
                    offset: Offset(0, isOverlay ? 12 : 16),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.035 : 0.34,
                    ),
                    blurRadius: 10,
                    spreadRadius: -3,
                    offset: const Offset(-2, -3),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: interior),
      ),
    );
  }
}

/// A compact frosted layer for primary mobile app bars.
class LiquidGlassAppBarBackground extends StatelessWidget {
  const LiquidGlassAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final palette = LiquidGlassPalette.from(colorScheme);

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: isDark ? 0.10 : 0.42),
                  colorScheme.surface.withValues(alpha: isDark ? 0.67 : 0.74),
                ),
                Color.alphaBlend(
                  palette.vividAccent.withValues(alpha: isDark ? 0.19 : 0.13),
                  colorScheme.surfaceContainer.withValues(
                    alpha: isDark ? 0.55 : 0.63,
                  ),
                ),
                colorScheme.surfaceContainer.withValues(
                  alpha: isDark ? 0.62 : 0.70,
                ),
              ],
              stops: const [0, 0.46, 1],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.72),
                width: 0.9,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.vividAccent.withValues(
                  alpha: isDark ? 0.14 : 0.10,
                ),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.borderRadius,
    required this.brightColor,
    required this.accentColor,
    required this.shadeColor,
    required this.strokeWidth,
  });

  final BorderRadius borderRadius;
  final Color brightColor;
  final Color accentColor;
  final Color shadeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rim = borderRadius.toRRect(bounds).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        [brightColor, accentColor, shadeColor, accentColor],
        const [0, 0.36, 0.74, 1],
      );
    canvas.drawRRect(rim, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) {
    return borderRadius != oldDelegate.borderRadius ||
        brightColor != oldDelegate.brightColor ||
        accentColor != oldDelegate.accentColor ||
        shadeColor != oldDelegate.shadeColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
