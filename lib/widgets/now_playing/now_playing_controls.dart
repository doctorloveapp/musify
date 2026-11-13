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

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/now_playing/player_glass.dart';
import 'package:musify/widgets/position_slider.dart';

class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({required this.metadata, super.key});

  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final live = metadata.extras?['isLive'] == true;
    final canOpenArtist = _canOpenArtist(metadata);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: metadata.title,
          child: Text(
            metadata.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: MediaQuery.sizeOf(context).width < 360 ? 22 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.18,
            ),
          ),
        ),
        if (metadata.artist?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canOpenArtist
                  ? () => _openArtistPage(context, metadata)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  metadata.artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        if (!live) ...[
          const SizedBox(height: 14),
          const RepaintBoundary(child: PositionSlider()),
        ],
        const SizedBox(height: 16),
        PlayerControlButtons(metadata: metadata),
      ],
    );
  }

  bool _canOpenArtist(MediaItem metadata) {
    final info = _extractArtistInfo(metadata);
    return !offlineMode.value &&
        (info.artist.isNotEmpty ||
            info.artistId.isNotEmpty ||
            info.sourceSongId.isNotEmpty);
  }

  void _openArtistPage(BuildContext context, MediaItem metadata) {
    final info = _extractArtistInfo(metadata);
    final lookup = info.artistId.isNotEmpty
        ? info.artistId
        : info.artist.isNotEmpty
        ? info.artist
        : info.sourceSongId;

    if (lookup.isEmpty) return;

    final router = GoRouter.of(context);
    final artistPath = NavigationManager.artistPath(context, lookup);
    final artistData = {
      'ytid': info.artistId.isNotEmpty ? info.artistId : lookup,
      if (info.artist.isNotEmpty) 'title': info.artist,
      if (info.sourceSongId.isNotEmpty) 'sourceSongId': info.sourceSongId,
      if (info.videoAuthor.isNotEmpty) 'videoAuthor': info.videoAuthor,
      'source': 'youtube-artist',
      'isArtist': true,
      'list': [],
    };

    Navigator.of(context).pop();
    unawaited(router.push(artistPath, extra: artistData));
  }

  ({String artist, String artistId, String sourceSongId, String videoAuthor})
  _extractArtistInfo(MediaItem metadata) {
    return (
      artist: metadata.artist?.trim() ?? '',
      artistId: metadata.extras?['artistId']?.toString().trim() ?? '',
      sourceSongId: metadata.extras?['ytid']?.toString().trim() ?? '',
      videoAuthor: metadata.extras?['videoAuthor']?.toString().trim() ?? '',
    );
  }
}

/// Binds the existing queue and player commands to presentation-only controls.
class PlayerControlButtons extends StatelessWidget {
  const PlayerControlButtons({required this.metadata, super.key});

  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return StreamBuilder<List<MediaItem>>(
      initialData: audioHandler.queue.value,
      stream: audioHandler.queue,
      builder: (context, queueSnapshot) => ValueListenableBuilder<bool>(
        valueListenable: shuffleNotifier,
        builder: (context, shuffled, _) =>
            ValueListenableBuilder<AudioServiceRepeatMode>(
              valueListenable: repeatNotifier,
              builder: (context, repeat, _) => StreamBuilder<PlaybackState>(
                initialData: audioHandler.playbackState.value,
                stream: audioHandler.playbackState.distinct(
                  (previous, next) =>
                      previous.playing == next.playing &&
                      previous.processingState == next.processingState,
                ),
                builder: (context, playbackSnapshot) {
                  final state = playbackSnapshot.data!;
                  final loading =
                      state.processingState == AudioProcessingState.loading ||
                      state.processingState == AudioProcessingState.buffering;
                  final completed =
                      state.processingState == AudioProcessingState.completed;
                  return PlayerTransportRow(
                    playing: state.playing,
                    loading: loading,
                    completed: completed,
                    shuffled: shuffled,
                    repeating: repeat != AudioServiceRepeatMode.none,
                    repeatOne: repeat == AudioServiceRepeatMode.one,
                    live: metadata.extras?['isLive'] == true,
                    playLabel: loading
                        ? l10n.loading
                        : completed
                        ? l10n.replay
                        : state.playing
                        ? l10n.pause
                        : l10n.play,
                    previousLabel: l10n.skipToPrevious,
                    nextLabel: l10n.skipToNext,
                    shuffleLabel: l10n.shuffle,
                    repeatLabel: l10n.repeat,
                    onPlay: loading
                        ? null
                        : completed
                        ? () => audioHandler.playAgain()
                        : state.playing
                        ? audioHandler.pause
                        : audioHandler.play,
                    onPrevious:
                        audioHandler.hasPrevious ||
                            repeat != AudioServiceRepeatMode.none
                        ? () => audioHandler.skipToPrevious()
                        : null,
                    onNext:
                        audioHandler.hasNext ||
                            repeat == AudioServiceRepeatMode.one
                        ? () => repeat == AudioServiceRepeatMode.one
                              ? audioHandler.playAgain()
                              : audioHandler.skipToNext()
                        : null,
                    onShuffle: () => audioHandler.setShuffleMode(
                      shuffled
                          ? AudioServiceShuffleMode.none
                          : AudioServiceShuffleMode.all,
                    ),
                    onRepeat: () {
                      final AudioServiceRepeatMode next;
                      if (repeat == AudioServiceRepeatMode.none) {
                        next = (queueSnapshot.data?.length ?? 0) <= 1
                            ? AudioServiceRepeatMode.one
                            : AudioServiceRepeatMode.all;
                      } else if (repeat == AudioServiceRepeatMode.all) {
                        next = AudioServiceRepeatMode.one;
                      } else {
                        next = AudioServiceRepeatMode.none;
                      }
                      repeatNotifier.value = next;
                      audioHandler.setRepeatMode(next);
                    },
                  );
                },
              ),
            ),
      ),
    );
  }
}
