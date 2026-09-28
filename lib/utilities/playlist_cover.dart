import 'dart:math';

import 'package:musify/utilities/song_source.dart';

const generatedPlaylistCoverIdsKey = 'generatedCoverSongIds';

bool hasCustomPlaylistCover(Map playlist) {
  final image = playlist['image']?.toString().trim();
  return image != null && image.isNotEmpty;
}

/// Keeps the automatically selected artwork stable by storing song identities
/// in the playlist map. Existing selections survive app restarts and are only
/// repaired when songs disappear or new slots become available.
bool ensureGeneratedPlaylistCover(Map playlist, {Random? random}) {
  if (hasCustomPlaylistCover(playlist)) {
    return playlist.remove(generatedPlaylistCoverIdsKey) != null;
  }

  final songs = (playlist['list'] as List? ?? const []).whereType<Map>();
  final candidates = <String, Map>{};
  for (final song in songs) {
    final identity = songIdentity(song);
    if (identity != null && identity.isNotEmpty) {
      candidates.putIfAbsent(identity, () => song);
    }
  }

  final targetLength = min(
    4,
    candidates.values.map(_artworkIdentity).toSet().length,
  );
  final previous = (playlist[generatedPlaylistCoverIdsKey] as List? ?? const [])
      .map((id) => id.toString())
      .toList(growable: false);
  final selected = <String>[];
  final selectedArtwork = <String>{};
  for (final id in previous) {
    final song = candidates[id];
    if (song != null && selectedArtwork.add(_artworkIdentity(song))) {
      selected.add(id);
      if (selected.length == targetLength) break;
    }
  }

  if (selected.length < targetLength) {
    final remaining =
        candidates.keys
            .where((id) => !selected.contains(id))
            .toList(growable: true)
          ..shuffle(random ?? Random());
    for (final id in remaining) {
      final song = candidates[id]!;
      if (!selectedArtwork.add(_artworkIdentity(song))) continue;
      selected.add(id);
      if (selected.length == targetLength) break;
    }
  }

  if (_sameIds(previous, selected)) return false;
  playlist[generatedPlaylistCoverIdsKey] = selected;
  return true;
}

List<Map> generatedPlaylistCoverSongs(Map playlist) {
  if (hasCustomPlaylistCover(playlist)) return const [];

  final songs = (playlist['list'] as List? ?? const []).whereType<Map>();
  final byIdentity = <String, Map>{};
  for (final song in songs) {
    final identity = songIdentity(song);
    if (identity != null) byIdentity.putIfAbsent(identity, () => song);
  }

  final selected = <Map>[];
  final artworkIds = <String>{};
  final ids = (playlist[generatedPlaylistCoverIdsKey] as List? ?? const []).map(
    (id) => id.toString(),
  );
  for (final id in ids) {
    final song = byIdentity[id];
    if (song != null && artworkIds.add(_artworkIdentity(song))) {
      selected.add(song);
    }
  }

  // Repair the view defensively when an older persisted selection contained
  // duplicate artwork. The next playlist write will persist the repaired set.
  for (final song in byIdentity.values) {
    if (selected.length == 4) break;
    if (artworkIds.add(_artworkIdentity(song))) selected.add(song);
  }
  return selected.take(4).toList(growable: false);
}

/// Returns the exact set of unique covers needed by the adaptive mosaic.
/// Three available covers intentionally render as a clean two-way split.
List<Map> playlistMosaicSongs(Iterable<Map> songs) {
  final unique = <Map>[];
  final artworkIds = <String>{};
  for (final song in songs) {
    if (artworkIds.add(_artworkIdentity(song))) unique.add(song);
    if (unique.length == 4) break;
  }
  if (unique.length >= 4) return unique.take(4).toList(growable: false);
  if (unique.length >= 2) return unique.take(2).toList(growable: false);
  return unique.take(1).toList(growable: false);
}

String _artworkIdentity(Map song) {
  for (final key in ['artworkPath', 'highResImage', 'image', 'lowResImage']) {
    final value = song[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return 'artwork:$value';
  }
  return 'song:${songIdentity(song) ?? song.hashCode}';
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
