/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/liquid_glass.dart';
import 'package:musify/widgets/shapes/four_sided_cookie_shape.dart';

class CustomBar extends StatelessWidget {
  CustomBar(
    this.tileName,
    this.tileIcon, {
    this.description,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final String tileName;
  final IconData tileIcon;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.onSecondaryContainer;
    final isDark = colorScheme.brightness == Brightness.dark;
    final glassPalette = LiquidGlassPalette.from(colorScheme);
    final baseColor =
        backgroundColor ??
        colorScheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.56 : 0.68,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: isDark ? 0.08 : 0.34),
              baseColor,
            ),
            Color.alphaBlend(
              glassPalette.vividAccent.withValues(alpha: isDark ? 0.12 : 0.085),
              baseColor,
            ),
            Color.alphaBlend(
              glassPalette.deepAccent.withValues(alpha: isDark ? 0.10 : 0.045),
              baseColor,
            ),
          ],
          stops: const [0, 0.54, 1],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.64),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                FourSidedCookieShape(
                  size: 52,
                  color: Color.alphaBlend(
                    glassPalette.vividAccent.withValues(
                      alpha: isDark ? 0.20 : 0.13,
                    ),
                    colorScheme.secondaryContainer,
                  ),
                  child: Icon(tileIcon, size: 26, color: effectiveIconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tileName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textColor ?? colorScheme.onSurface,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    textColor?.withValues(alpha: 0.75) ??
                                    colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
