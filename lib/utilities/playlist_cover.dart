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

  final targetLength = min(4, candidates.length);
  final previous = (playlist[generatedPlaylistCoverIdsKey] as List? ?? const [])
      .map((id) => id.toString())
      .toList(growable: false);
  final selected = <String>[];
  for (final id in previous) {
    if (candidates.containsKey(id) && !selected.contains(id)) {
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
    selected.addAll(remaining.take(targetLength - selected.length));
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

  final ids = (playlist[generatedPlaylistCoverIdsKey] as List? ?? const []).map(
    (id) => id.toString(),
  );
  return ids.map((id) => byIdentity[id]).whereType<Map>().take(4).toList();
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
