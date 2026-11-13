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

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/widgets/flip_card.dart';
import 'package:musify/widgets/liquid_glass.dart';
import 'package:musify/widgets/now_playing/bottom_actions_row.dart';
import 'package:musify/widgets/now_playing/now_playing_artwork.dart';
import 'package:musify/widgets/now_playing/now_playing_controls.dart';
import 'package:musify/widgets/now_playing/player_glass.dart';
import 'package:musify/widgets/queue_list_view.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final _lyricsController = FlipCardController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final large = size.width > 900 && size.height > 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<MediaItem?>(
                initialData: audioHandler.mediaItem.valueOrNull,
                stream: audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final metadata = snapshot.data;
                  if (metadata == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final content = PlayerContentLayout(
                    live: metadata.extras?['isLive'] == true,
                    artworkBuilder: (side) => NowPlayingArtwork(
                      dimension: side,
                      metadata: metadata,
                      lyricsController: _lyricsController,
                    ),
                    controls: NowPlayingControls(metadata: metadata),
                    actions: BottomActionsRow(
                      metadata: metadata,
                      iconSize: 22,
                      isLargeScreen: large,
                      lyricsController: _lyricsController,
                    ),
                  );
                  if (!large) return content;
                  return Row(
                    children: [
                      Expanded(flex: 5, child: content),
                      const SizedBox(width: 12),
                      const Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 8, 24, 20),
                          child: LiquidGlassSurface(
                            showShadow: false,
                            padding: EdgeInsets.all(12),
                            child: QueueWidget(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          PlayerGlassButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: FluentIcons.chevron_down_24_regular,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'MUSIFY',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n!.nowPlaying,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
