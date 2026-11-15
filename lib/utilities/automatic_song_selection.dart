import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Only automatic related-song picks are filtered; explicit playback is untouched.
/// Adapted from gokadzev/Musify snapshot 8126f0c1 (GPL-3.0-or-later).
Video? selectAutomaticSong(Iterable<Video> candidates) {
  for (final video in candidates) {
    if (video.isLive) continue;
    final duration = video.duration;
    if (duration == null ||
        (duration >= const Duration(seconds: 30) &&
            duration <= const Duration(minutes: 8))) {
      return video;
    }
  }
  return null;
}
