import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/liquid_glass.dart';

/// A circular glass control. Refraction is painted, never backdrop-filtered,
/// so transport/position updates do not recompute a blur for every button.
class PlayerGlassButton extends StatelessWidget {
  const PlayerGlassButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
    this.diameter = 48,
    this.iconSize = 24,
    this.primary = false,
    this.selected = false,
    super.key,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final double diameter;
  final double iconSize;
  final bool primary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final palette = LiquidGlassPalette.from(scheme);
    final accented = primary || selected;
    final fill = primary
        ? scheme.primary
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: selected ? 0.30 : 0.11),
            scheme.surfaceContainerHigh.withValues(alpha: dark ? 0.88 : 0.90),
          );
    final foreground = primary
        ? scheme.onPrimary
        : selected
        ? scheme.primary
        : scheme.onSurface;

    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: onPressed != null,
        selected: selected ? true : null,
        onTap: onPressed,
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (accented ? palette.vividAccent : Colors.black)
                      .withValues(alpha: dark ? 0.26 : 0.14),
                  blurRadius: primary ? 30 : 18,
                  offset: const Offset(0, 9),
                  spreadRadius: primary ? 0 : -3,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: dark ? 0.08 : 0.65),
                  blurRadius: 9,
                  spreadRadius: -2,
                  offset: const Offset(-2, -3),
                ),
              ],
            ),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        Colors.white.withValues(
                          alpha: primary
                              ? (dark ? 0.20 : 0.09)
                              : (dark ? 0.18 : 0.58),
                        ),
                        fill,
                      ),
                      fill,
                      Color.alphaBlend(
                        palette.deepAccent.withValues(
                          alpha: primary ? 0.06 : 0.15,
                        ),
                        fill,
                      ),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                  border: Border.all(
                    color: accented
                        ? scheme.primary.withValues(alpha: dark ? 0.80 : 0.55)
                        : Colors.white.withValues(alpha: dark ? 0.32 : 0.85),
                    width: primary ? 1.4 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    customBorder: const CircleBorder(),
                    excludeFromSemantics: true,
                    child: SizedBox.square(
                      dimension: diameter,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 2,
                            child: IgnorePointer(
                              child: Container(
                                width: diameter * 0.74,
                                height: diameter * 0.34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(diameter),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: dark ? 0.14 : 0.30,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconTheme(
                            data: IconThemeData(
                              color: onPressed == null
                                  ? foreground.withValues(alpha: 0.34)
                                  : foreground,
                              size: iconSize,
                            ),
                            child: child ?? Icon(icon),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presentation only: callbacks are supplied by the existing player adapter.
class PlayerTransportRow extends StatelessWidget {
  const PlayerTransportRow({
    required this.playLabel,
    required this.previousLabel,
    required this.nextLabel,
    required this.shuffleLabel,
    required this.repeatLabel,
    required this.onPlay,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
    this.playing = false,
    this.loading = false,
    this.completed = false,
    this.shuffled = false,
    this.repeating = false,
    this.repeatOne = false,
    this.live = false,
    super.key,
  });

  final String playLabel, previousLabel, nextLabel, shuffleLabel, repeatLabel;
  final VoidCallback? onPlay, onPrevious, onNext;
  final VoidCallback onShuffle, onRepeat;
  final bool playing, loading, completed, shuffled, repeating, repeatOne, live;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 312;
        final sideSize = compact ? 48.0 : 52.0;
        final playSize = compact ? 72.0 : 80.0;
        final play = PlayerGlassButton(
          tooltip: playLabel,
          onPressed: loading ? null : onPlay,
          primary: true,
          diameter: playSize,
          iconSize: 36,
          icon: completed
              ? FluentIcons.arrow_counterclockwise_24_regular
              : playing
              ? FluentIcons.pause_24_filled
              : FluentIcons.play_24_filled,
          child: loading
              ? SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : null,
        );
        if (live) return Center(child: play);
        final previous = PlayerGlassButton(
          tooltip: previousLabel,
          onPressed: onPrevious,
          icon: FluentIcons.previous_24_filled,
          diameter: sideSize,
          iconSize: 26,
        );
        final next = PlayerGlassButton(
          tooltip: nextLabel,
          onPressed: onNext,
          icon: FluentIcons.next_24_filled,
          diameter: sideSize,
          iconSize: 26,
        );
        final shuffle = PlayerGlassButton(
          tooltip: shuffleLabel,
          onPressed: onShuffle,
          selected: shuffled,
          icon: FluentIcons.arrow_shuffle_24_filled,
          iconSize: 21,
        );
        final repeat = PlayerGlassButton(
          tooltip: repeatLabel,
          onPressed: onRepeat,
          selected: repeating,
          icon: repeatOne
              ? FluentIcons.arrow_repeat_1_24_filled
              : FluentIcons.arrow_repeat_all_24_filled,
          iconSize: 21,
        );
        if (constraints.maxWidth < 264) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [previous, play, next],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [shuffle, repeat],
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [shuffle, previous, play, next, repeat],
        );
      },
    );
  }
}

class PlayerArtworkFrame extends StatelessWidget {
  const PlayerArtworkFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LiquidGlassSurface(
    variant: LiquidGlassVariant.hero,
    borderRadius: BorderRadius.circular(32),
    padding: const EdgeInsets.all(7),
    child: ClipRRect(borderRadius: BorderRadius.circular(25), child: child),
  );
}

/// Fits the cover to actual space, with scrolling reserved for small screens
/// and large accessibility text. No FittedBox shrinks interactive targets.
class PlayerContentLayout extends StatelessWidget {
  const PlayerContentLayout({
    required this.artworkBuilder,
    required this.controls,
    required this.actions,
    this.live = false,
    super.key,
  });

  final Widget Function(double side) artworkBuilder;
  final Widget controls;
  final Widget actions;
  final bool live;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final landscape = width >= 600 && width > height;
      if (landscape) {
        final side = math.min(height - 36, width * 0.40).clamp(120.0, 400.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox.square(
                    dimension: side,
                    child: artworkBuilder(side),
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [controls, const SizedBox(height: 22), actions],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      final horizontal = width < 350 ? 20.0 : 26.0;
      final maxSide = math.min<double>(width - horizontal * 2, 354);
      final reserved =
          (live ? 274.0 : 400.0) + math.max<double>(0, scale - 1) * 130;
      final side = math.min<double>(
        maxSide,
        math.max<double>(156, height - reserved),
      );
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, height - 28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox.square(
                      dimension: side,
                      child: artworkBuilder(side),
                    ),
                  ),
                  const SizedBox(height: 26),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: controls,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: actions,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
