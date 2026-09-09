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
import 'package:musify/services/common_services.dart';
import 'package:musify/utilities/media_duration.dart';
import 'package:musify/utilities/song_source.dart';

Map mediaItemToMap(MediaItem mediaItem) {
  final extras = mediaItem.extras;
  return {
    'id': mediaItem.id,
    'ytid': extras?['ytid'],
    'album': mediaItem.album,
    'artist': mediaItem.artist ?? '',
    'title': mediaItem.title,
    'artistId': extras?['artistId'],
    'videoAuthor': extras?['videoAuthor'],
    'highResImage': extras?['highResImage'] ?? mediaItem.artUri.toString(),
    'lowResImage': extras?['lowResImage'],
    'isLive': extras?['isLive'] ?? false,
    'source': extras?['source'],
    'localUri': extras?['localUri'],
    'audioPath': extras?['audioPath'],
    'artworkPath': extras?['artworkPath'],
    'mediaStoreId': extras?['mediaStoreId'],
    'volumeName': extras?['volumeName'],
    'missing': extras?['missing'] ?? false,
    if (mediaItem.duration case final duration?) 'duration': duration.inSeconds,
  };
}

MediaItem mapToMediaItem(Map song) {
  final ytid = song['ytid']?.toString();
  final isDeviceLocal = isDeviceLocalSong(song);
  final offlineSong = !isDeviceLocal && ytid != null
      ? getOfflineSongByYtid(ytid)
      : <String, dynamic>{};
  final isOffline = offlineSong.isNotEmpty;

  final artworkPath = isDeviceLocal
      ? song['artworkPath']?.toString()
      : isOffline
      ? offlineSong['artworkPath']?.toString()
      : null;
  final remoteArtwork = song['highResImage']?.toString();
  final artUri = artworkPath != null && artworkPath.isNotEmpty
      ? Uri.file(artworkPath)
      : remoteArtwork != null && remoteArtwork.isNotEmpty
      ? Uri.tryParse(remoteArtwork)
      : null;

  return MediaItem(
    id: (song['id'] ?? song['ytid']).toString(),
    album: song['album']?.toString(),
    artist: song['artist']?.toString().trim() ?? '',
    title: song['title']?.toString() ?? '',
    artUri: artUri,
    duration: readMediaDuration(song['duration']),
    extras: {
      'lowResImage': song['lowResImage'],
      'ytid': song['ytid'],
      'artistId': song['artistId'],
      'videoAuthor': song['videoAuthor'],
      'isLive': song['isLive'],
      'highResImage': song['highResImage'],
      'source': song['source'],
      'localUri': song['localUri'],
      'audioPath': isOffline ? offlineSong['audioPath'] : song['audioPath'],
      'artworkPath': artworkPath,
      'mediaStoreId': song['mediaStoreId'],
      'volumeName': song['volumeName'],
      'missing': song['missing'] ?? false,
      'artWorkPath': artworkPath ?? remoteArtwork ?? '',
    },
  );
}

/// Compares two Duration objects with tolerance for minor differences.
///
/// This prevents unnecessary updates when duration values have minor variations
/// (e.g., due to buffering or precision differences).
bool durationEquals(Duration? prev, Duration? curr) {
  if (prev == curr) return true;
  if (prev == null || curr == null) return prev == curr;

  // Consider durations equal if they differ by less than 1 second
  return (prev - curr).abs() < const Duration(seconds: 1);
}
